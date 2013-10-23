# -*- coding: utf-8 -*-
require $RECORDER_ROOT_PATH + '/data_in_database/reservation.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/program.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/channel.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/recorded.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/configure.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/program_category.rb'
require $RECORDER_ROOT_PATH + '/utility/reserve_utility.rb'

module Recorder
  module Utility
    module UIUtility
      # 番組IDから番組オブジェクトを返す
      def self.get_program(program_id_str, message)
        begin
          program_id = BSON::ObjectId.from_string(program_id_str)
        rescue
          message << "IDが不正です。"
          return nil
        end
        program = Program.new(program_id)
        unless program.exist?
          message << "番組ID(#{program_id_str})に該当する番組は存在しません。"
          return nil
        end
        return program
      end

      # 番組IDの文字列とメッセージ格納用の(文字列)オブジェクトを受け取り、番組を予約する。
      # ・予約に成功したらtrueを返す。
      def self.try_reserve_from_program(program_id_str, message)
        program = get_program(program_id_str, message)
        return false unless program
        unless reservation = ReserveUtility.reserve_from_program(program, message)
          return false
        end
        message << "予約に成功しました。予約ID:(#{reservation.id})。"
        return true
      end

      # チャンネルスキャン用に録画予約を行う。
      # ・予約された件数を返す。
      def self.reserve_for_channel_scan
        scan_channel = ($config["scan_terrestrial_channel_under"]..$config["scan_terrestrial_channel_top"]).to_a
        ReserveUtility.reserve_for_channel_epg(:terrestrial, $config["epg_record_length_terrestrial"], scan_channel)
        channel_num = scan_channel.size
        if $config["bs_active?"]
          ReserveUtility.reserve_for_channel_epg(:satellite, $config["epg_record_length_satellite"], [$config["scan_bs_channel"]])
          channel_num += 1
        end
        if $config["cs_active?"]
          ReserveUtility.reserve_for_channel_epg(:satellite, $config["epg_record_length_satellite"], [$config["scan_cs_channel"]])
          channel_num += 1
        end
        return channel_num
      end

      # チャンネルの表示順序をスワップ
      def self.swap_channel_order(channel_id_str1, channel_id_str2)
        begin
          channel_id1 = BSON::ObjectId.from_string(channel_id_str1)
          channel_id2 = BSON::ObjectId.from_string(channel_id_str2)
        rescue
          return false
        end
        channel1 = Channel.new(channel_id1)
        channel2 = Channel.new(channel_id2)
        return false unless channel1.exist? && channel2.exist?
        Channel.swap_order_number(channel1, channel2)
        return true
      end

      # チャンネルを非アクティブ化
      def self.channel_switch_non_active(channel_id_str)
        begin
          channel_id = BSON::ObjectId.from_string(channel_id_str)
        rescue
          return false
        end
        channel = Channel.new(channel_id)
        return false unless channel.exist?
        channel.switch_non_active
        return true
      end

      # カテゴリカラー変更
      def self.change_category_color(category_id_str, color)
        category = ProgramCategory.new(BSON::ObjectId.from_string(category_id_str))
        category.set_color(color)
        return true
      rescue
        return false
      end
    end
  end
end
