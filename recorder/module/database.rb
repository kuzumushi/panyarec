# -*- coding: utf-8 -*-
module Recorder
  require 'mongo'
  require 'json'

  module DataBase
    require 'singleton'

    class Connection
      # シングルトン・パターン
      include Singleton

      # MongoDB接続設定ファイルのパス
      SETTING_FILE_PATH = $RECORDER_ROOT_PATH + '/setting/mongodb_setting.json'

      # 使用するDB名を指定する
      def self.specify_dbname(dbname)
        @dbname = dbname
      end

      # 指定されたDB名を取得する
      def self.get_specified_dbname
        return @dbname
      end

      # DB接続
      def initialize
        File.open(SETTING_FILE_PATH) do |f|
          setting = JSON.load(f)
          @dbname = self.class.get_specified_dbname || setting["mongo_dbname"]
          @connection = Mongo::Connection.new(setting["mongo_addr"], setting["mongo_port"])
        end
      end

      # DB(DB名)内の全てのコレクションを削除する
      def drop_database
        @connection.drop_database(@dbname)
      end

      # コレクション参照
      def collection(collection_name)
        return @connection.db(@dbname).collection(collection_name)
      end
    end

    class Accessor
      def initialize(collection_name)
        @collection = Connection.instance.collection(collection_name)
      end

      # DBに任意のオブジェクトを追加する。
      # ・DB内でのidを返す。
      def database_insert(hash_data)
        raise "argument must be instance of Hash." unless hash_data.instance_of?(Hash)
        return my_collection.insert(hash_data)
      end

      # DBの任意のオブジェクトを削除する。
      # ・削除されたオブジェクトの件数を返す。
      def database_remove(condition_hash)
        raise "argument must be instance of Hash." unless condition_hash.instance_of?(Hash)
        response = my_collection.remove(condition_hash)
        return response["n"]
      end

      # DBの任意のオブジェクトの任意のフィールド値を変更する。
      # ・条件に合致するオブジェクトが複数ある場合は、マッチした全てのオブジェクトが更新される。
      # ・変更されたオブジェクトの件数を返す。
      def database_update(condition_hash, update_field_name, update_value)
        raise "argument must be instance of Hash." unless condition_hash.instance_of?(Hash)
        response = my_collection.update(condition_hash, {'$set' => {update_field_name => update_value}}, {:multi => true})
        return response["n"]
      end

      # 条件に合致するDB内の全オブジェクトを返す。
      # ・Mongo::Cursorを返す。Mongo::Cursorについては参照:http://api.mongodb.org/ruby/current/Mongo/Cursor.html
      def database_find(condition_hash)
        raise "argument must be instance of Hash." unless condition_hash.instance_of?(Hash)
        return my_collection.find(condition_hash)
      end

      # IDからオブジェクトを返す
      def database_find_by_id(id)
        return my_collection.find_one('_id' => id)
      end

      # コレクションへの参照を取得
      def my_collection
        return @collection
      end
    end
  end
end
