# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module Recorder
  module UnitTest
    # テスト用ライブラリをロード
    require "test/unit"
    require $RECORDER_ROOT_PATH + '/unit_test/lib/test_unit_extensions.rb'

    # テスト対象をロード
    require $RECORDER_ROOT_PATH + '/data_in_database/data_in_database.rb'

    # テスト
    class  DataInDataBaseTest < Test::Unit::TestCase
      TEST_DB_NAME = "test_ruby_recorder"

      def setup
        DataBase::Connection.specify_dbname(TEST_DB_NAME)
        @collection = DataBase::Connection.instance.collection(DataInDataBase.to_s)
        @collection.drop
        DataInDataBase.remove_all_class_instance_variable
      end

      must "create" do
        accessor = DataInDataBase.create("name" => "test")
        assert_equal 1, @collection.count
        assert_equal "test", @collection.find_one["name"]
        assert_equal @collection.find_one["_id"], accessor.read("_id")
      end

      must "each" do
        @collection.insert("name" => "test1", "point" => 1)
        @collection.insert("name" => "test2", "point" => 2)
        point_sum = 0
        DataInDataBase.find.each do |accessor|
          point_sum += accessor.read("point")
        end
        assert_equal 3, point_sum
      end


      must "disappear and error of read and write" do
        accessor = DataInDataBase.create("name" => "test")
        assert_equal 1, @collection.count
        accessor.disappear
        assert_equal 0, @collection.count
        assert_raise RuntimeError do
          accessor.read("count")
        end
        assert_raise RuntimeError do
          accessor.write("type", "hoge")
        end
      end

      must "write_plural" do
        accessor = DataInDataBase.create("name" => "test", "type" => "hoge", "color" => "red")
        accessor.write_plural({
          "type"  => "puyo",
          "color" => "blue"
        })
        assert_equal "puyo", accessor.read("type")
        assert_equal "blue", accessor.read("color")
      end
    end
  end
end