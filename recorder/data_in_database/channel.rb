# -*- coding: utf-8 -*-
require $RECORDER_ROOT_PATH + '/data_in_database/data_in_database.rb'
require $RECORDER_ROOT_PATH + '/command/epgdump.rb'

module Recorder
  class Channel < DataInDataBase
    # 種別(GR/BS/CS)識別シンボル
    CLASSIFICATION_SYMBOLS = [:gr, :bs, :cs]

    # チャンネル情報を新規登録
    # ・channel_epgにおける同一のIDが既に登録済みの場合はnilを返す。
    def self.make_channel(channel_epg_id, physical_channel, classification_symbol, channel_epg_hash)
      synchronize do
        return nil if find_by_channel_epg_id(channel_epg_id)
        return create("channel_epg_id"        => channel_epg_id,
                      "physical_channel"      => physical_channel,
                      "classification_symbol" => check_classification_symbol(classification_symbol),
                      "channel_epg"           => channel_epg_hash,
                      "active"                => true,
                      "order_number"          => next_order_number)
      end
    end

    # 順序番号の最大値＋１を取得
    def self.next_order_number
      return 0 if size == 0
      return find.sort{|c1,c2| c2.get_order_number <=> c1.get_order_number}.first.get_order_number + 1
    end

    # 順序番号をスワップ
    def self.swap_order_number(channel1, channel2)
      synchronize do
        tmp_order_number = channel1.get_order_number
        channel1.write("order_number", channel2.get_order_number)
        channel2.write("order_number", tmp_order_number)
      end
    end

    # channel_epg_idから、DB内に登録されているチャンネルを返す。
    # ・チャンネルが見つからない場合はnilを返す。
    def self.find_by_channel_epg_id(channel_epg_id)
      return find("channel_epg_id" => channel_epg_id).first
    end

    def self.find_by_physical_channel(physical_channel)
      return find("physical_channel" => physical_channel)
    end

    # classification_symbolの入力ミスをチェックする
    # ・既定の種別に合致しない場合は例外を投げる。
    # ・合致する場合はそのままclassification_symbolを返す。
    def self.check_classification_symbol(classification_symbol)
      unless CLASSIFICATION_SYMBOLS.include?(classification_symbol)
        raise "unknown type_symbol \"#{classification_symbol}\"."
      end
      return classification_symbol
    end

    def self.terrestrial_all
      return find("classification_symbol" => :gr)
    end

    def self.satellite_all
      return find("$or" => [{"classification_symbol" => :bs}, {"classification_symbol" => :cs}])
    end

    def self.bs_all
      return find("classification_symbol" => :bs)
    end

    def self.cs_all
      return find("classification_symbol" => :cs)
    end

    def switch_non_active
      write("active", false)
    end

    def get_physical_channel
      return read("physical_channel")
    end

    def get_type_symbol
      case
      when terrestrial?
        return :terrestrial
      when satellite?
        return :satellite
      else
        raise "channel type miss matched. channel_id:(#{channel_id})}"
      end
    end

    def get_channel_epg_id
      return read("channel_epg_id")
    end

    def get_channel_epg
      return Epgdump::ChannelEpg.new(read("channel_epg"))
    end

    def get_order_number
      return read("order_number")
    end

    def active?
      return !!read("active")
    end

    def terrestrial?
      return read("classification_symbol") == :gr
    end

    def satellite?
      return read("classification_symbol") == :bs || read("classification_symbol") == :cs
    end

    def bs?
      return read("classification_symbol") == :bs
    end

    def cs?
      return read("classification_symbol") == :cs
    end

    def classification_match?(classification)
      return read("classification_symbol").to_s == classification.to_s
    end

    def get_classification_symbol
      return read("classification_symbol")
    end

    def using_for_getting_epg?
      return !!read("using_for_getting_epg")
    end

    def set_using_for_getting_epg
      write("using_for_getting_epg", true)
    end
  end
end
