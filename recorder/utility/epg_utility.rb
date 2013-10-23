# -*- coding: utf-8 -*-
require $RECORDER_ROOT_PATH + '/data_in_database/reservation.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/program.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/channel.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/recorded.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/configure.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/program_category.rb'
require $RECORDER_ROOT_PATH + '/command/epgdump.rb'

module Recorder
  module Utility
    module EpgUtility
      # EPG情報を抽出し、番組表を更新する
      # ・録画済みオブジェクトの配列を引数にとる。
      def self.update_from_recorded(array_of_recorded)
        epgdump = Epgdump.new($config["epgdump_path"], $config["tmp_dir_path"])
        array_of_recorded.each do |recorded|
          epg_collection = epgdump.parse(recorded.get_file_path, recorded.get_physical_channel)
          if recorded.channel_epg?
            register_channel_epg(epg_collection)
            if channel_for_epg = Channel.find_by_physical_channel(recorded.get_physical_channel).first
              channel_for_epg.set_using_for_getting_epg
            else
              Log << "チャンネル#{recorded.get_physical_channel}chをEPG更新用チャンネルに" +
                "登録しようと試みましたが失敗しました。"
            end
          end
          register_program_epg(epg_collection) if recorded.program_epg?
        end
      end

      # Epgdumpが吐き出したEPG情報を元に、番組表を更新する。
      def self.register_program_epg(epg_collection)
        epg_collection.each do |program_epg, channel_epg|
          next unless channel = Channel.find_by_channel_epg_id(channel_epg.get_cid)
          event_id              = program_epg.get_event_id
          range                 = program_epg.get_start_time..program_epg.get_end_time
          classification_symbol = channel.get_classification_symbol
          category_ids          = ProgramCategory.receive(program_epg).map{|category| category.id}
          Program.set_program(event_id, channel.id, range, program_epg.to_h, classification_symbol, category_ids)
        end
      end

      # Epgdumpが吐き出したEPG情報を元に、チャンネルリストを更新する。
      def self.register_channel_epg(epg_collection)
        epg_collection.each_channel do |channel_epg|
          physical_channel      = channel_epg.get_physical_channel
          classification_symbol = channel_epg.get_classification_symbol
          Channel.make_channel(channel_epg.get_cid, physical_channel, classification_symbol, channel_epg.to_h)
        end
      end
    end
  end
end
