# -*- coding: utf-8 -*-
module Recorder
  require 'json'

  # Piro77氏版epgdump
  class Epgdump
    def initialize(epgdump_path, tmp_dir_path)
      @epgdump_path = epgdump_path
      @tmp_dir_path = tmp_dir_path
    end

    # JSON形式で出力されたものを変換し、DumpedEpgオブジェクトとして出力
    def parse(ts_path, recording_physical_channel)
      dumpfile_path = @tmp_dir_path + File::basename(ts_path) + ".epgdump"
      `#{@epgdump_path} json #{ts_path} #{dumpfile_path}`
      epg = nil
      File.open(dumpfile_path) do |f|
        epg = JSON.load(f)
      end
      File.delete(dumpfile_path)
      return EpgCollection.new(epg, recording_physical_channel)
    end

    # 各チャンネルごとのEPG情報を束ねるコレクション
    class EpgCollection
      include Enumerable

      def initialize(epg_array, recording_physical_channel)
        @epg_array = epg_array
        @recording_physical_channel = recording_physical_channel
      end

      # コレクション内の全ての番組EPG情報についてイテレート
      # ・ブロック引数は (ProgramEpg, そのプログラムのChannelEpg)
      def each(&block)
        @epg_array.each do |channel_epg_hash|
          channel_epg = ChannelEpg.new(channel_epg_hash, @recording_physical_channel)
          channel_epg_hash["programs"].each do |program_epg_hash|
            block.call(ProgramEpg.new(program_epg_hash), channel_epg)
          end
        end
      end

      # コレクション内の全てのチャンネルEPG情報についてイテレート
      # ・ブロック引数はChannelEpg
      def each_channel(&block)
        @epg_array.each do |channel_epg_hash|
          channel_epg = ChannelEpg.new(channel_epg_hash, @recording_physical_channel)
          block.call(channel_epg)
        end
      end
    end

    # チャンネルについての
    class ChannelEpg
      def initialize(channel_epg_hash, recording_physical_channel=nil)
        @channel_epg_hash = channel_epg_hash.clone
        @channel_epg_hash.delete("programs")
        @recording_physical_channel = recording_physical_channel
      end

      def to_h
        @channel_epg_hash
      end

      def equal?(channel_epg)
        return self.get_cid == channel_epg.get_cid
      end

      def get_cid
        return @channel_epg_hash["id"]
      end

      def get_name
        return @channel_epg_hash["name"]
      end

      def get_physical_channel
        case get_classification_symbol
        when :gr
          raise "can't find physical_channel." unless @recording_physical_channel
          return @recording_physical_channel
        when :bs, :cs
          return get_cid[3..-1].to_i
        end
      end

      def get_classification_symbol
        case get_cid[0..1]
        when "GR"
          return :gr
        when "BS"
          return :bs
        when "CS"
          return :cs
        else
          raise "unknown classification #{get_cid[0..1]} (from #{get_cid})."
        end
      end
    end

    class ProgramEpg
      TITLE_KEY  = "title"
      DETAIL_KEY = "detail"

      def initialize(program_epg_hash)
        @program_epg_hash = program_epg_hash.clone
      end

      def to_h
        return @program_epg_hash
      end

      def get_channel
        return @program_epg_hash["channel"]
      end

      def get_title
        return @program_epg_hash[TITLE_KEY]
      end

      def get_detail
        return @program_epg_hash[DETAIL_KEY]
      end

      def get_event_id
        return @program_epg_hash["event_id"]
      end

      def get_start_time
        return Time.at(@program_epg_hash["start"]/10000)
      end

      def get_end_time
        return Time.at(@program_epg_hash["end"]/10000)
      end

      def get_large_categories
        return @program_epg_hash["category"].map{|hash| hash["large"] && hash["large"]["ja_JP"]}.compact
      end

      def get_middle_categories
        return @program_epg_hash["category"].map{|hash| hash["middle"] && hash["large"]["ja_JP"]}.compact
      end
    end
  end
end
