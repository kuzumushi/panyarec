# -*- coding: utf-8 -*-
require $RECORDER_ROOT_PATH + '/data_in_database/data_in_database.rb'
require $RECORDER_ROOT_PATH + '/command/epgdump.rb'
require $RECORDER_ROOT_PATH + '/module/light_dsl.rb'
require $RECORDER_ROOT_PATH + '/module/time_descriptor.rb'

module Recorder
  require 'bson'

  class Program < DataInDataBase
    # 番組情報を登録
    # ・指定したevent_idの番組情報が既に登録されているかどうかで新規作成または更新を行う。
    def self.set_program(event_id, channel_id, range, program_epg_hash, classification_symbol, category_ids)
      case find_by_event_id(event_id, channel_id).size
      when 0
        return new_program(event_id, channel_id, range, program_epg_hash, classification_symbol, category_ids)
      when 1
        return update_program(event_id, channel_id, range, program_epg_hash, classification_symbol, category_ids)
      else
        raise "more than one event_id:(#{event_id}), channel_id:(#{channel_id}) already exists."
      end
    end

    # 番組情報を新規登録
    # ・set_programメソッドから呼ばれるのが基本。ただし単独で呼ぶことも可能。
    # ・既に同じevent_idの番組が登録されていたら例外を投げる。
    def self.new_program(event_id, channel_id, range, program_epg_hash, classification_symbol, category_ids)
      if find_by_event_id(event_id, channel_id).size > 0
        raise "event_id:(#{event_id}), channel_id:(#{channel_id}) already exists."
      end
      return create("event_id"      => event_id.to_i,
                    "channel_id"    => channel_id,
                    "start"         => range.begin,
                    "end"           => range.end,
                    "category_ids"  => category_ids,
                    "for_search"    => make_for_search(range, classification_symbol),
                    "program_epg"   => program_epg_hash)
    end

    # 番組情報をアップデート
    # ・set_programメソッドから呼ばれるのが基本。ただし単独で呼ぶことも可能。
    # ・同一event_idの番組が(一件)登録されていない場合は例外を投げる。
    def self.update_program(event_id, channel_id, range, program_epg_hash, classification_symbol, category_ids)
      if find_by_event_id(event_id, channel_id).size != 1
        raise "event_id:(#{event_id}), channel_id:(#{channel_id}) exists more than 1."
      end
      program = find_by_event_id(event_id, channel_id).first
      program.write_plural("channel_id"    => channel_id,
                           "start"         => range.begin,
                           "end"           => range.end,
                           "category_ids"  => category_ids,
                           "for_search"    => make_for_search(range, classification_symbol),
                           "program_epg"   => program_epg_hash)
      return program
    end

    def self.find_by_event_id(event_id, channel_id)
      find("event_id" => event_id.to_i, "channel_id" => channel_id)
    end

    def self.make_for_search(range, classification_symbol)
      return {
        "week"           => range.begin.getlocal.wday,
        "start"          => range.begin.getlocal.hour * 60 + range.begin.getlocal.min,
        "classification" => classification_symbol.to_s
      }
    end

    # ファイル名を自動生成
    def get_auto_filename
      # temp
      return "test#{read("start").getlocal.strftime("%m%d%H%M%S")}_#{read("end")-read("start")}sec.ts"
    end

    # 番組の放送時刻をRangeオブジェクトで返す
    def get_range
      return read("start")..read("end")
    end

    def get_start_time
      return read("start")
    end

    def get_end_time
      return read("end")
    end

    def get_event_id
      return read("event_id")
    end

    def get_category_ids
      return read("category_ids")
    end

    def get_first_category_id
      return read("category_ids").first
    end

    # EPG情報を取得
    def get_program_epg
      return Epgdump::ProgramEpg.new(read("program_epg"))
    end

    # チャンネルIDを取得
    def get_channel_id
      return read("channel_id")
    end

    # 番組検索用内部クラス
    class Search
      extend LightDSL
      
      define_type 'キーワード(タイトルのみ)' do
        @key  = "keyword"
        value do |keyword_str|
          {"program_epg.#{Epgdump::ProgramEpg::TITLE_KEY}" => Regexp.new(keyword_str)}
        end
      end

      define_type 'キーワード(タイトル及び番組説明)' do
        @key  = "extend_keyword"
        value do |keyword_str|
          {"$or" =>
            [
             {"program_epg.#{Epgdump::ProgramEpg::TITLE_KEY}" => Regexp.new(keyword_str)},
             {"program_epg.#{Epgdump::ProgramEpg::DETAIL_KEY}" => Regexp.new(keyword_str)}
            ]
          }
        end
      end

      define_type 'チャンネルID' do
        @key  = "channel_id"
        value do |channel_id_str|
          {"channel_id" => BSON::ObjectId.from_string(channel_id_str)}
        end
      end

      define_type '種別(GR/BS/CS)' do
        @key  = "classification"
        value do |classification_str|
          {"for_search.classification" => classification_str}
        end
      end

      define_type '曜日(0から6, 0:日曜, 6:土曜)' do
        @key  = "week"
        value do |week_num_str|
          {"for_search.week" => week_num_str.to_i}
        end
      end

      define_type '開始時刻時間帯([下界, 上界]を0から1440=24*60で指定)' do
        @key  = "time_range" 
        value do |lower_str, upper_str|
          lower = lower_str.to_i
          upper = upper_str.to_i
          if lower <= upper
            {"for_search.start" => {"$gte" => lower, "$lte" => upper}}
          else
            {"$or" =>
              [
               {"for_search.start" => {"$gte" => lower, "$lte" => 24*60}},
               {"for_search.start" => {"$gte" => 0,     "$lte" => upper}}
              ]
            }
          end
        end
      end

      define_type 'カテゴリ指定' do
        @key  = "category"
        value do |category_id_str|
          {"category_ids" => BSON::ObjectId.from_string(category_id_str)}
        end
      end

      def self.new(search_hash, limit=nil, page=nil)
        super(make_condition_hash(search_hash), limit, page)
      end

      def self.make_condition_hash(search_hash)
        return search_hash.inject(Hash.new) do |condition_hash, (key, val)|
          break condition_hash if val.empty?
          additional_hash = pull_value(val, false) do
            @key == key.to_s
          end
          condition_hash.merge(additional_hash || {})
        end                                               
      end

      def initialize(condition_hash, limit, page)
        @mongo_cursor   = Program.low_select_non_map(condition_hash, {:sort => {"start" => 1}})
        @limit = (limit || @mongo_cursor.count).to_i
        @page  = (page || 0).to_i
      end

      # limitにより制限される前の、素の合致件数を返す
      def get_matched_number
        return @mongo_cursor.count
      end

      def get_now_page_number
        return @page
      end

      def get_all_page_number
        div = (get_matched_number / @limit)
        if get_matched_number % @limit
          return  div + 1
        else
          return div
        end
      end

      # 検索に合致した番組をマップ
      # ・ブロック引数は|番組オブジェクト|
      def next_program_map(&block)
        selected_mongo_cursor = @mongo_cursor.skip(@page * @limit).limit(@limit)
        @page += 1
        return Program.map_to_instance(selected_mongo_cursor).map(&block)
      end

      def each(&block)
        Program.map_to_instance(@mongo_cursor).each(&block)
      end

      def rewind
        @page = 0
      end

      def end?
        return @page * @limit >= @matched_number
      end
    end
  end
end
