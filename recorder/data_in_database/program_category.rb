# -*- coding: utf-8 -*-
require $RECORDER_ROOT_PATH + '/data_in_database/data_in_database.rb'
require $RECORDER_ROOT_PATH + '/command/epgdump.rb'

module Recorder
  class ProgramCategory < DataInDataBase
    DEFAULT_COLOR_SETTING = {
      "情報／ワイドショー"     => "#e6e6fa", #lavender
      "その他"                 => "#ffffff", #white
      "ドキュメンタリー／教養" => "#ffb6c1", #lightpink
      "バラエティ"             => "#f5deb3", #wheat
      "趣味／教育"             => "#cd853f", #peru
      "スポーツ"               => "#87ceeb", #skyblue
      "ニュース／報道"         => "#48d1cc", #mediumturquoise
      "音楽"                   => "#7fffd4", #aquamarine
      "ドラマ"                 => "#bc8f8f", #rosybrown
      "映画"                   => "#c0c0c0", #silver
      "劇場／公演"             => "#cd5c5c", #indianred
      "アニメ／特撮"           => "#ff7f50", #coral
      "福祉" => ""
    }

    def self.receive(program_epg)
      return regist_categories(program_epg).uniq{|n| n.id}
    end

    def self.regist_categories(program_epg)
      return program_epg.get_large_categories.inject([]) do |added_categories, category_name|
        new_category_entry = {
          "level" => "large",
          "name"  => category_name
        }
        if find(new_category_entry).size == 0
          new_category = new_category_entry.merge("color" => DEFAULT_COLOR_SETTING[category_name])
          added_categories + [create(new_category)]
        else
          added_categories + [find(new_category_entry).first]
        end
      end
    end

    def self.make_color_hash(default_color_str="")
      return find.inject(Hash.new) do |color_hash, category|
        color_hash.merge(category.id => category.get_color || default_color_str)
      end
    end

    def get_color
      return read("color")
    end

    def get_name
      return read("name")
    end

    def get_level
      return read("level")
    end

    def set_color(color)
      write("color", color)
    end
  end
end
