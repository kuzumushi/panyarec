# -*- coding: utf-8 -*-
require $RECORDER_ROOT_PATH + '/data_in_database/reservation.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/program.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/channel.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/configure.rb'

module Recorder
  module Utility
    module ReserveUtility
      # 番組情報から予約登録
      def self.reserve_from_program(program, error_status="")
        channel = Channel.new(program.get_channel_id)
        range = program.get_range
        physical_channel = channel.get_physical_channel
        file_path = $config["default_ts_dir"] + program.get_auto_filename
        type_symbol  = channel.get_type_symbol
        tuner_number = max_tuner_number(type_symbol)
        return Reservation.reserve(range, physical_channel, file_path, type_symbol, error_status, tuner_number) do
          set_program_id(program.id)
        end
      end

      # 指定チャンネル(物理チャンネル + 種別)を指定録画長にて可及的速やかに予約
      def self.reserve_asap(duration, physical_channel, type_symbol, &block)
        Reservation.synchronize do
          range = Reservation.next_free_range(duration, type_symbol, Time.now, max_tuner_number(type_symbol))
          file_path = $config["tmp_dir_path"] + 
            range.begin.getlocal.strftime("epg_%m%d%H%M%S_#{duration}sec_#{physical_channel}ch.ts")
          tuner_number = max_tuner_number(type_symbol)
          reservation = Reservation.reserve(range, physical_channel, file_path, type_symbol, "", tuner_number, &block)
          unless reservation
            raise "reservation for epg is faild. (#{duration}sec. #{physical_channel}ch. #{type_symbol})"
          end
          return reservation
        end
      end

      # チャンネル列を指定して番組EPG用に予約
      def self.reserve_for_program_epg_from_channels(array_of_channel)
        array_of_channel.each do |channel|
          case
          when channel.terrestrial?
            recording_length = $config["epg_record_length_terrestrial"]
          when channel.satellite?
            recording_length = $config["epg_record_length_satellite"]
          else
            raise "channel type miss matched. channel_id:(#{channel_id})}"
          end
          physical_channel = channel.get_physical_channel
          type_symbol      = channel.get_type_symbol
          reserve_asap(recording_length, physical_channel, type_symbol) do
            set_program_epg_flag
            set_remove_soon_flag
          end
        end
        return array_of_channel.size
      end

      # 物理チャンネル列と種別と録画長を指定してチャンネルスキャン用に予約
      # ・番組情報の取得も同時に行う。
      def self.reserve_for_channel_epg(type_symbol, record_length, physical_channels)
        physical_channels.each do |physical_channel|
          reserve_asap(record_length, physical_channel, type_symbol) do
            set_program_epg_flag
            set_channel_epg_flag
            set_remove_soon_flag
          end
        end
        return physical_channels.size
      end

      # 予約データのアップデート(番組時間変更追従)
      def self.reservation_update_as_program_updated
        Reservation.find.select{|r| r.get_option.program_id?}.each do |reservation|
          program_id = reservation.get_option.get_program_id
          new_range = Program.new(program_id).get_range
          if new_range != reservation.get_range
            Reservation.reserve_change(reservation, new_range, nil)
          end
        end
      end

      # 放送波typeの最大チューナー数を取得する
      def self.max_tuner_number(type_symbol)
        case type_symbol
        when :terrestrial
          return $config["max_terrestrial_tuner_number"]
        when :satellite
          return $config["max_satellite_tuner_number"]
        else
          raise "can't find max_tuner_number"
        end
      end
    end
  end
end

