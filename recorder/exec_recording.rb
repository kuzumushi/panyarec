# -*- coding: utf-8 -*-
require $RECORDER_ROOT_PATH + '/command/recpt1.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/reservation.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/recorded.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/program.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/log.rb'
require $RECORDER_ROOT_PATH + '/module/tuner_entry.rb'
require $RECORDER_ROOT_PATH + '/utility/reserve_utility.rb'

module Recorder
  # 録画実行クラス
  class ExecRecording
    # 予約オブジェクトを受け取り、録画を開始する。
    def initialize(reservation)
      @reservation = reservation
      @reservation.call_recording_will_start
      Thread.new do
        begin
          do_record
        rescue => error
          Log << error
          @reservation.call_recording_missed
        ensure
          @reservation.call_recording_finished
          @finished = true
        end
      end
    end

    def finished?
      return @finished
    end

    def finish
      sleep(0.1) until @recpt1
      @recpt1.stop
      @reservation.call_recording_missed
      sleep(0.1) until finished?
    end

    private

    # 録画処理
    def do_record
      sleep(0.1) until @reservation.recording_start_time?(Time.now)
      tuner_use(@reservation.get_type_symbol, $config["tuner_secure_timeout_sec"]) do
        init_recording_length
        recpt1 = Recpt1.new($config["recpt1_path"], $config["recpt1ctl_path"], @reservation.get_logger)
        status = recpt1.rec(@reservation.make_recording_option_str, @reservation.get_physical_channel, @recording_length, @reservation.get_file_path)
        unless status
          raise "予約bsonid:(#{@reservation.id})#{@reservation.get_physical_channel}ch.のrecpt1の録画開始に失敗しました。"
        end
        @recpt1 = recpt1
        fix_recpt1_delay
        make_recorded do
          until recpt1.finished?
            update_recording_length
            sleep(0.5)
          end
        end
      end
    end

    # 録画長を計算し、初期化する。
    def init_recording_length
      @end_time   = @reservation.get_recording_end_time
      @start_time = Time.now
      @recording_length = @end_time - @start_time
    end

    # 予約データをチェックし、終了時間に変更があれば録画長を変更。
    def update_recording_length
      new_end_time = @reservation.get_recording_end_time
      if @end_time != new_end_time
        @recording_length += (new_end_time - @end_time)
        @end_time = new_end_time
        @recpt1.ctl_time(@recording_length)
      end
    end

    # recpt1コマンドの実行に時間が掛かった場合は録画長を補正
    def fix_recpt1_delay
      if @start_time + 1 < @recpt1.get_started_time
        @recording_length = @end_time - @recpt1.get_started_time
        @recpt1.ctl_time(@recording_length)
      end
    end

    # 録画済データを作成し、渡されたブロックを呼び出す。
    # ・ブロックの呼び出しが終了 => 録画の終了 とみなす。
    # ・ブロックの呼出し後に(必ず)録画済オブジェクトの終了処理メソッドを呼び出す。
    def make_recorded(&block)
      recorded = Recorded.new_recorded(@reservation.id, @reservation.get_file_path, @reservation.get_physical_channel, @recpt1.get_started_time, @recpt1.get_cn)
      recorded.set_epg_flag(@reservation.get_option.program_epg?, @reservation.get_option.channel_epg?)
      begin
        block.call
      ensure
        reservation_hash = Reservation.pull_data_hash_by_id(@reservation.id)
        program_hash     = nil
        if @reservation.get_option.program_id?
          program_hash = Program.pull_data_hash_by_id(@reservation.get_option.get_program_id)
        end
        recorded.call_recording_finished(@recpt1.get_recorded_length, reservation_hash, program_hash)
      end
    end

    # チューナーを確保し、ブロックを呼び出す。
    # ・ブロックの呼出し後にチューナーを(必ず)解放する。
    def tuner_use(type_symbol, timeout_sec, &block)
      raise "no block given." unless block
      max_tuner_number = Utility::ReserveUtility.max_tuner_number(type_symbol)
      tuner = TunerEntry.acquire(type_symbol, max_tuner_number, timeout_sec)
      unless tuner
        raise "予約id:#{@reservation.id}の録画チューナーが確保できません。録画開始に失敗しました。"
      end
      begin
        block.call
      ensure
        TunerEntry.release(tuner)
      end
    end
  end
end
