# -*- coding: utf-8 -*-
require $RECORDER_ROOT_PATH + '/module/database.rb'

module Recorder
  require 'monitor'

  # DB上のデータの管理と各データへのアクセサ(インスタンス)を提供するクラス。
  class DataInDataBase
    # Timeオブジェクトの大小比較を整数値(秒数まで)で行うように変更
    class ::Time
      def <=>(other)
        return self.to_i <=> other.to_i
      end
    end

    # 同期モニタ
    def self.synchronize(&block)
      @monitor ||= Monitor.new
      @monitor.synchronize do
        block.call
      end
    end

    # クラスインスタンス変数を全て削除(テスト用)
    def self.remove_all_class_instance_variable
      instance_variables.each do |class_instance_variable_symbol|
        remove_instance_variable(class_instance_variable_symbol)
      end
    end

    # 任意の選択を施した後に各データはDataInDatabaseインスタンス(キャッシュ有)に変換して取得
    # ・任意の選択とはMongoCollectionの選択メソッドfind()及びカーソルメソッドsort()、skip()、limit()によるデータの検索・整列である。
    def self.low_select(condition_hash={}, select_hash={})
      return low_select_non_map(condition_hash, select_hash).map{|a| new(a["_id"], a)}
    end

    def self.low_select_non_map(condition_hash={}, select_hash={})
      return select(get_database_accessor.my_collection.find(condition_hash), select_hash)
    end

    def self.map_to_instance(mongo_cursor)
      mongo_cursor.map{|a| new(a["_id"], a)}
    end

    # 新規データをDB上に作成
    # ・作成したデータのアクセサを返す。
    def self.create(data_hash={})
      raise "argument must be instance of Hash." unless data_hash.instance_of?(Hash)
      id = get_database_accessor.database_insert(data_hash)
      return new(id)
    end

    # DB上のデータを取得
    # ・各データはDataInDatabaseインスタンスに変換される
    def self.find(condition_hash={})
      return get_database_accessor.database_find(condition_hash).map{|a| new(a["_id"])}
    end

    # オブジェクトの要素数を返す
    def self.size
      return get_database_accessor.my_collection.count
    end

    # IDからデータそのもの(ハッシュ)を返す
    # ・該当するIDが存在しなければnilを返す。
    def self.pull_data_hash_by_id(id)
      return get_database_accessor.database_find_by_id(id)
    end

    # インスタンスから特定フィールドの値を取得
    def self.read(instance, field_name)
      object = get_database_accessor.database_find_by_id(instance.id)
      raise "object id is invalid (unexist in databaes)." unless object
      return object[field_name]
    end

    # インスタンスから特定フィールドの値を変更
    def self.write(instance, field_name, value)
      updated_number = get_database_accessor.database_update({'_id' => instance.id}, field_name, value)
      raise "object id is invalid (unexist in databaes)." if updated_number == 0
    end

    # 特定データをDBから削除
    def self.delete(instance)
      removed_number = get_database_accessor.database_remove('_id' => instance.id)
      raise "object id is invalid (unexist in databaes)." if removed_number == 0
    end

    # 全オブジェクトを削除する
    # ・当然ながら復元不能なので注意。
    def self.delete_all
      get_database_accessor.my_collection.drop
    end

    attr_reader :id

    def initialize(id, cache_hash=nil)
      set_chache(cache_hash)
      @id = id
    end

    # キャッシュを登録し、次に値が変更されるまで(writeが呼ばれるまで)保持する。
    def set_chache(cache_hash)
      @cache = cache_hash
    end

    # 特定フィールドの値を取得
    def read(field_name)
      return @cache[field_name] if @cache
      return self.class.read(self, field_name)
    end

    # 特定フィールドの値を変更
    def write(field_name, value)
      @cache = nil
      self.class.write(self, field_name, value)
    end

    # DB上に存在するかどうか
    def exist?
      return !!self.class.read(self, "_id") rescue false
    end

    # (複数個の)特定フィールドの値を更新
    # ・フィールド名 => フィールド値のhashで指定
    def write_plural(hash)
      raise "argument must be instance of Hash." unless hash.instance_of?(Hash)
      hash.each do |field_name, value|
        write(field_name, value)
      end
    end

    # 自身をDB上から削除
    def disappear
      self.class.delete(self)
    end

    private_class_method

    # DBアクセサを取得
    def self.get_database_accessor
      return @database_accessor ||= DataBase::Accessor.new(self.to_s)
    end

    # Mongo::cursorインスタンス(=引数selected)にカーソルメソッドを再帰的に適用する
    def self.select(selected, select_hash)
      case
      when select_hash[:sort]
        return select(selected.sort(select_hash[:sort]), select_hash.reject{|key| key == :sort})
      when select_hash[:skip]
        return select(selected.skip(select_hash[:skip]), select_hash.reject{|key| key == :skip})
      when select_hash[:limit]
        number_before_limited = selected.count
        return select(selected.limit(select_hash[:limit]), select_hash.reject{|key| key == :limit})
      else
        return selected
      end
    end
  end
end
