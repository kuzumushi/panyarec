# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module Recorder
  module UnitTest
    # テスト用ライブラリをロード
    require "test/unit"
    require $RECORDER_ROOT_PATH + '/unit_test/lib/test_unit_extensions.rb'

    # テスト対象をロード
    require $RECORDER_ROOT_PATH + '/module/database.rb'

    # テスト
    class  DataBaseTest < Test::Unit::TestCase

      TEST_DB_NAME = "test_ruby_recorder"
      TEST_COLLECTION_NAME = "TEST_COLLECTION"

      def setup
        DataBase::Connection.specify_dbname(TEST_DB_NAME)
        connection = DataBase::Connection.instance
        @collection = connection.collection(TEST_COLLECTION_NAME)
        @collection.drop
      end

      must "insert" do
        @database_accessor = DataBase::Accessor.new(TEST_COLLECTION_NAME)
        @database_accessor.database_insert("name" => "test1")
        @database_accessor.database_insert("name" => "test2")
        assert_equal 2, @collection.count
      end

      must "remove" do
        @database_accessor = DataBase::Accessor.new(TEST_COLLECTION_NAME)
        @collection.insert("name" => "test3")
        @collection.insert("name" => "test3")
        @collection.insert("name" => "test4")
        assert_equal 3, @collection.count
        @database_accessor.database_remove("name" => "test3")
        assert_equal 1, @collection.count
        assert_equal "test4", @collection.find_one["name"]
      end

      must "update" do
        @database_accessor = DataBase::Accessor.new(TEST_COLLECTION_NAME)
        @collection.insert("name" => "test5", "type" => "hoge")
        @collection.insert("name" => "test6", "type" => "piyo")
        @collection.insert("name" => "test7", "type" => "hoge", "color" => "red")
        @database_accessor.database_update({"type" => "hoge"}, "color", "blue")
        assert_equal "blue", @collection.find_one("name" => "test5")["color"]
        assert_equal nil,    @collection.find_one("name" => "test6")["color"]
        assert_equal "blue", @collection.find_one("name" => "test7")["color"]
      end

      must "find" do
        @database_accessor = DataBase::Accessor.new(TEST_COLLECTION_NAME)
        @collection.insert("name" => "test8", "type" => "hoge")
        @collection.insert("name" => "test9", "type" => "piyo")
        @collection.insert("name" => "test10", "type" => "hoge")
        assert_equal 2, @database_accessor.database_find("type" => "hoge").count
      end

      must "find_by_id" do
        @database_accessor = DataBase::Accessor.new(TEST_COLLECTION_NAME)
        id1 = @collection.insert("name" => "test11")
        id2 = @collection.insert("name" => "test12")
        assert_equal "test11", @database_accessor.database_find_by_id(id1)["name"]
        assert_equal "test12", @database_accessor.database_find_by_id(id2)["name"]
      end
    end
  end
end