# -*- coding: utf-8 -*-
require $RECORDER_ROOT_PATH + '/data_in_database/data_in_database.rb'
require $RECORDER_ROOT_PATH + '/module/range_table.rb'
require $RECORDER_ROOT_PATH + '/module/command_option.rb'
require $RECORDER_ROOT_PATH + '/module/method_caller.rb'

module Recorder
  class Reservation < DataInDataBase
    # 種別(地上波/衛星波)識別シンボル
    TYPE_SYMBOLS = [:terrestrial, :satellite]

    private_class_method :create

    # 予約登録
    # ・時刻、物理チャンネル、録画ファイル名、種別は必須。
    # ・予約不可能ならfalseを返す。
    # ・ブロック内でオプションの設定が可能。
    def self.reserve(range, physical_channel, file_path, type_symbol, error_status="", max_overlap=Float::INFINITY, &block)
      synchronize do
        return false unless reservable?(range, file_path, type_symbol, [], error_status, max_overlap)
        return create(
          "start"            => range.begin,
          "end"              => range.end,
          "physical_channel" => physical_channel,
          "file_path"        => file_path,
          "type_symbol"      => check_type_symbol(type_symbol),
          "log"              => [],
          "option"           => ReservationOption.create(block).to_h
        )
      end
    end

    # 予約情報の変更
    # ・時刻と保存先のみ変更可能
    # ・変更不可能ならfalseを返す。
    def self.reserve_change(reservation, range, file_path, error_status="", max_overlap=Float::INFINITY)
      synchronize do
        new_range    = range || reservation.get_range
        type_symbol  = reservation.get_type_symbol
        return false unless reservable?(new_range, file_path, type_symbol, [reservation.id], error_status, max_overlap)
        reservation.write_plural(
          "start"     => new_range.begin,
          "end"       => new_range.end,
          "file_path" => file_path || reservation.get_file_path
        )
      end
      return true
    end

    # 安全に予約を取り消す
    # ・すでに録画が開始されていたら正常終了させる。
    # ・録画が既に終了していたら例外を投げる。
    def self.safe_delete(reservation)
      synchronize do
        raise "reservation already finished." if reservation.read("finished")
        if reservation.read("started")
          reservation.write("end", Time.now)
          reservation.write("specified_stop", true)
        else
          reservation.disappear
        end
      end
    end

    # 次の予約(未開始の予約の中で、開始時刻が最も早いもの)を返す
    # ・予約が一件も存在しない場合はnilを返す。
    def self.next_reservation
      synchronize do
        first = find.select{|r| r.wait?}.sort{|a,b| a.read("start") <=> b.read("start")}.first
        return nil unless first
        return first
      end
    end

    # 次のlength秒の録画可能時刻を取得する
    def self.next_free_range(length, type_symbol, begining=Time.now, max_overlap=Float::INFINITY)
      check_type_symbol(type_symbol)
      time_table = RangeTable.new
      find.select{|r| !r.missed? && r.read("type_symbol") == type_symbol}.each do |r|
        time_table.add(r.get_range)
      end
      begin_time = time_table.next_range_begin(begining, length, max_overlap)
      return (begin_time)..(begin_time + length)
    end

    # type_symbolの入力ミスをチェックする
    # ・既定の種別に合致しない場合は例外を投げる。
    # ・合致する場合はそのままtype_symbolを返す。
    def self.check_type_symbol(type_symbol)
      raise "unknown type_symbol \"#{type_symbol}\"." unless TYPE_SYMBOLS.include?(type_symbol)
      return type_symbol
    end

    # 予約可能かどうか
    # ・trueなら予約可能。
    # ・falseの場合、引数error_statusにエラーメッセージを格納する。
    def self.reservable?(range, file_path, type_symbol, except_ids=[], error_status="", max_overlap=Float::INFINITY)
      if file_path && file_path_dupe?(file_path, except_ids)
        error_status << "録画ファイルの保存先が既に存在しているか、他の予約と重複しています。"
        return false
      end
      if get_reservation_overlap(range, type_symbol, except_ids) >= max_overlap
        error_status << "録画時刻の録画重複数が最大チューナー数を上回ります。"
        return false
      end
      return true
    end

    # 保存先ファイル名が既に存在していないか、あるいは他の予約と重複していないか
    # ・falseなら予約可能。
    def self.file_path_dupe?(file_path, except_ids=[])
      return false unless file_path
      return true if File.exist?(file_path)
      return find("file_path" => file_path).reject{|r| r.missed? || except_ids.index(r.read("_id"))}.size != 0
    end

    # 既にある予約データと予約時刻が重なる場合、重複数が最大チューナー数を上回っていないかどうか
    # ・falseなら予約可能。
    def self.get_reservation_overlap(range, type_symbol, except_ids=[])
      check_type_symbol(type_symbol)
      time_table = RangeTable.new
      find.select{|r| !r.missed? && r.read("type_symbol") == type_symbol}.reject{|r| except_ids.index(r.read("_id"))}.each do |r|
        time_table.add(r.get_range)
      end
      return time_table.get_max_overlap(range)
    end

    # ログを追記
    def log_push(message, time=Time.now)
      write("log", read("log").push("time" => time, "message" => message))
    end

    # 録画処理開始の直前に呼ばれるメソッド
    def call_recording_will_start
      write("started", true)
    end

    # 録画処理の終了時に呼ばれるメソッド
    # ・録画処理が開始されたら、録画の成功/失敗に関わらず、終了時に必ず呼ばれる。
    def call_recording_finished
      write("finished", true)
    end

    # 録画が失敗した際に呼ばれるメソッド
    # ・失敗の種類や録画処理自体が開始されたか等に関わらず、正常に録画が行われなかったことが判明した時点で必ず呼ばれる。
    def call_recording_missed
      write("missed", true)
    end

    # 録画時間の(登録値の)Rangeオブジェクトを取得
    # ・start_earlyやstop_earlyが指定されている場合は実際の録画時間とget_rangeで取得する時間は異なる点に注意。
    def get_range
      return read("start")..read("end")
    end

    # 実際に録画を開始する時刻を取得
    def get_recording_start_time
      return read("start") - read("start_early").to_i
    end

    # 実際に録画を終了する時刻を取得
    def get_recording_end_time
      return read("end") - read("end_early").to_i
    end

    # 実際に録画を行う時刻のRangeオブジェクトを取得
    def get_recording_range
      return get_recording_start_time..get_recording_end_time
    end

    # 物理チャンネル取得
    def get_physical_channel
      return read("physical_channel")
    end

    # 録画先ファイルを取得
    def get_file_path
      return read("file_path")
    end

    # 種別のシンボルを取得
    def get_type_symbol
      return read("type_symbol")
    end

    # オプション設定オブジェクトを取得
    def get_option
      return ReservationOption.from_hash(read("option"))
    end

    # ログ追記オブジェクトの取得
    # ・<<演算子でログの追記が可能
    def get_logger
      return MethodCaller.new(self) do
        append :<<, :log_push
      end
    end

    # ログの取得
    def get_log
      return read("log")
    end

    # 録画時にコマンドに渡すオプション引数文字列を生成
    def make_recording_option_str
      option = get_option
      command_option = CommandOption.create do
        set "--b25", ["--strip"]
        if option.udp?
          set "--udp", ["--addr", option.get_udp_addr], ["--port", option.get_udp_port]
        end
      end
      return command_option.to_s
    end

    # 時刻timeが録画開始時刻を過ぎていたら真を返す。
    def recording_start_time?(time)
      return get_recording_start_time <= time
    end

    # time時からsec秒以内に録画終了時刻となる場合、真を返す。
    def finishing_in?(sec, time=Time.now)
      return get_recording_end_time <= time - sec
    end

    # 録画が失敗したかどうか
    def missed?
      return !!read("missed")
    end

    # 録画開始を待っている状態かどうか
    def wait?
      return !(read("started") || read("missed"))
    end

    # 種別がTerrestrialかどうか
    def terrestrial?
      return read("type_symbol") == :terrestrial
    end

    # 種別がSatelliteかどうか
    def satellite?
      return read("type_symbol") == :satellite
    end

    # 予約オプション管理クラス
    class ReservationOption
      private_class_method :new

      # ブロックを渡してインスタンスを新規作成
      def self.create(block)
        option = new
        option.instance_eval(&block) if block
        return option
      end

      # ハッシュからインスタンスを生成
      def self.from_hash(option_hash)
        return new(option_hash)
      end

      def initialize(option_hash=Hash.new)
        @option_hash = option_hash
      end

      # インスタンスをハッシュに変換して出力
      def to_h
        return @option_hash
      end

      # 設定セッター
      def set_program_id(program_id)
        @option_hash["program_id"] = program_id
      end

      def set_program_epg_flag
        @option_hash["program_epg"] = true
      end

      def set_channel_epg_flag
        @option_hash["channel_epg"] = true
      end

      def set_udp(addr, port)
        @option_hash["udp"] = {"addr" => addr, "port" => port}
      end

      def set_sid(sid)
        @option_hash["sid"] = sid
      end

      def set_remove_soon_flag
        @option_hash["remove_soon"] = true
      end

      # 設定ゲッター
      def program_id?
        return !!@option_hash["program_id"]
      end

      def get_program_id
        return @option_hash["program_id"]
      end

      def program_epg?
        return !!@option_hash["program_epg"]
      end

      def channel_epg?
        return !!@option_hash["channel_epg"]
      end

      def udp?
        return !!@option_hash["udp"]
      end

      def get_udp_addr
        return @option_hash["udp"]["addr"]
      end

      def get_udp_port
        return @option_hash["udp"]["port"]
      end

      def sid?
        return !!@option_hash["sid"]
      end

      def get_sid
        return @option_hash["sid"]
      end

      def remove_soon?
        return @option_hash["remove_soon"]
      end
    end
  end
end
