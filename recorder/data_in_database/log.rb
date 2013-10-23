# -*- coding: utf-8 -*-
require $RECORDER_ROOT_PATH + '/data_in_database/data_in_database.rb'
require $RECORDER_ROOT_PATH + '/module/light_dsl.rb'

module Recorder
  class Log < DataInDataBase
    extend LightDSL

    define_type 'エラー' do
      @type         = :error
      @target_class = ::StandardError
      value do |error|
        {
          "type"    => @type,
          "name"    => @name,
          "time"    => Time.now,
          "message" => "#{error.class}: #{error}",
          "detail"  => "#{error.backtrace}"
        }
      end
    end

    define_type '動作報告' do
      @type         = :info
      @target_class = ::String
      value do |string|
        {
          "type"    => @type,
          "name"    => @name,
          "time"    => Time.now,
          "message" => string,
          "detail"  => ""
        }
      end
    end

    define_type 'チューナー使用報告' do
      @type = :tuner_use
      value do |reservation_id, tuner_name, start_time, end_time|
        {
          "type"    => @type,
          "name"    => @name,
          "time"    => Time.now,
          "message" => "予約#{reservation_id}の録画のためにチューナー(#{tuner_name})を使用しました。",
          "detail"  => "(time:#{start_time})～(time:#{end_time})"
        }
      end
    end

    # オブジェクトの型から種別を判定してログに書き込む
    def self.<<(object)
      data_hash = pull_value(object) do
        @target_class && object.is_a?(@target_class)
      end
      return create(data_hash)
    end

    # 種別を指定してログに書き込む
    def self.write(type, *args)
      data_hash = pull_value(args) do
        @type == type
      end
      return create(data_hash)
    end

    def self.select_type(type_str=nil, limit=nil, page=0)
      if type_str && !type_str.empty?
        condition_hash = {"type" => type_str.to_sym}
      else
        condition_hash = {}
      end
      mongo_cursor = low_select_non_map(condition_hash).sort("time" => -1)
      if limit
        return map_to_instance(mongo_cursor.skip(page.to_i*limit.to_i).limit(limit.to_i))
      end
      return map_to_instance(mongo_cursor)
    end

    def self.type_size(type_str=nil)
      if type_str && !type_str.empty?
        condition_hash = {"type" => type_str.to_sym}
      else
        condition_hash = {}
      end
      return low_select_non_map(condition_hash).count
    end

    def get_time
      return read("time")
    end

    def get_name
      return read("name")
    end

    def get_message
      return read("message")
    end

    def get_detail
      return read("detail")
    end
  end
end
