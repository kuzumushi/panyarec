# -*- coding: utf-8 -*-
require $RECORDER_ROOT_PATH + '/data_in_database/data_in_database.rb'

module Recorder
  class Recorded < DataInDataBase
    private_class_method :create

    # 録画済データを新規作成
    def self.new_recorded(reservation_id, file_path, physical_channel, started_time, cn)
      return create(
        "reservation_id"    => reservation_id,
        "file_path"         => file_path,
        "physical_channel"  => physical_channel,
        "started_time"      => started_time,
        "cn"                => cn
      )
    end

    # 録画が終了しているEPG用の録画データ全て返す。
    def self.epg
      return find("for_epg" => {"$exists" => true}).select{|r| r.finished?}
    end

    # 録画が終了した際に呼ばれるメソッド
    def call_recording_finished(recorded_length, reservation_hash, program_hash)
      write("finished", true)
      write("recorded_length", recorded_length)
      write("reservation", reservation_hash)
      write("program", program_hash)
    end

    # EPG用録画の場合のフラグをセットするメソッド
    # ・引数の値はいずれもtrue/false
    # ・どちらもfalseなら何も行わずにnilを返す。
    def set_epg_flag(for_program, for_channel)
      return nil unless for_program || for_channel
      write("for_epg", {"program" => for_program, "channel" => for_channel})
    end

    # 番組情報EPG更新用の録画データであれば真を返す
    def program_epg?
      return !!(read("for_epg") && read("for_epg")["program"])
    end

    # チャンネル情報EPG更新用の録画データであれば真を返す
    def channel_epg?
      return !!(read("for_epg") && read("for_epg")["channel"])
    end

    # 録画が終了していたら真を返す
    def finished?
      return !!read("finished")
    end

    def get_reservation_id
      return read("reservation_id")
    end

    def get_file_path
      return read("file_path")
    end

    def get_physical_channel
      return read("physical_channel")
    end

    def get_started_time
      return read("started_time")
    end

    def get_cn
      return read("cn")
    end

    def get_recorded_length
      return read("recorded_length")
    end

    def get_reservation_hash
      return read("reservation")
    end

    def get_program_hash
      return read("program")
    end

    def file_exist?
      return File.exist?(get_file_path)
    end

    # 録画ファイルも含め、完全に削除する。
    # ・録画ファイルの削除に失敗した場合、録画情報の削除は行わずにfalseを返す
    def completely_delete
      begin
        File.delete(get_file_path) if file_exist?
      rescue
        return false
      end
      self.disappear
      return true
    end

    # 検索用内部クラス
    class Search
      def initialize(search_hash, limit, page)
        condition_hash = make_condition_hash(search_hash)
        @mongo_cursor = Recorded.low_select_non_map(condition_hash, {:sort => {"started_time" => -1}})
        @limit = limit.to_i
        @page = page.to_i
      end

      def make_condition_hash(search_hash)
        return {}
      end

      def map(&block)
        selected_mongo_cursor = @mongo_cursor.skip(@page * @limit).limit(@limit)
        Recorded.map_to_instance(selected_mongo_cursor).map(&block)
      end

      def matched_size
        return @mongo_cursor.count
      end
    end        
  end
end
