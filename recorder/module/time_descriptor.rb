# -*- coding: utf-8 -*-
module Recorder
  require 'time'

  class TimeDescriptor
    # 文字列から適当にTimeオブジェクトに変換
    def from_str(time_str)
      if time_str.lenght == 14
        t = time_str
        return Time.local(t[0..3], t[4..5], t[6..7], t[8..9], t[10..11], t[12..13])
      end
      return Time.parse(time_str)
    end

    # Timeオブジェクトを適当に文字列に変換
    def desc(time)
      return time.getlocal.strftime("%m月%d日%H:%M:%S")
    end

    # Timeオブジェクトを適当に[時:分:秒]の文字列に変換
    def desc_hms(time)
      return time.getlocal.strftime("%H:%M:%S")
    end

    # Timeオブジェクトを適当に[時:分]の文字列に変換
    def desc_hm(time)
      return time.getlocal.strftime("%H:%M")
    end

    # Timeオブジェクトの時間差を適当な文字列に変換
    def len_hm(time1, time2)
      total_sec = (time2 - time1).to_i
      min  = (total_sec/60) % 60
      hour = total_sec/3600
      desc_str = ""
      desc_str << "#{hour}時間" if hour > 0
      desc_str << "#{min}分" if min > 0
      return desc_str
    end

    def sub_div_pos(time1, time2, div=1)
      return [((time1 - time2).to_i / div), 0].max
    end

    def for_js_parse(time)
      return time.getlocal.strftime("%Y/%m/%d %H:%M:%S")
    end

    def make_time_tiles(start_time, end_time, segment_min, sec_per_px)
      tiles = Array.new
      top = 0
      segment_start = Time.local(start_time.year, start_time.mon, start_time.day, start_time.hour, start_time.min)
      loop do
        time_tile = Hash.new
        next_segment = segment_start + (segment_min - (segment_start.hour*60 + segment_start.min)%segment_min) * 60
        height = (next_segment - segment_start).to_i / sec_per_px
        tiles.push(
          "index_time" => segment_start,
           "top"       => top,
           "height"    => height
        )
        break if next_segment >= end_time
        top += height
        segment_start = next_segment
      end
      return tiles
    end
  end
end