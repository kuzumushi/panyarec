# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module Recorder
  module UnitTest
    # テスト用ライブラリをロード
    require "test/unit"
    require $RECORDER_ROOT_PATH + '/unit_test/lib/test_unit_extensions'

    # テスト対象をロード
    require $RECORDER_ROOT_PATH + '/data_in_database/configure.rb'

    # テスト
    class  ConfigureTest < Test::Unit::TestCase
      TEST_DB_NAME = "test_ruby_recorder"

      def setup
        DataBase::Connection.specify_dbname(TEST_DB_NAME)
        Configure.delete_all
        Configure.init_configuration
        @config = Configure.get_accessor
      end

      must "get reader and read one data" do
        assert_equal "hello", @config["test_setting"]
      end

      must "write" do
        @config.write("test_setting", "hoge")
        assert_equal "hoge", @config["test_setting"]
        @config.write("test_setting", "fuga")
        assert_equal "fuga", @config["test_setting"]
      end

      must "init" do
        @config.write("test_setting", "alternative setting")
        Configure.synchronize do
          Configure.init_configuration
          @config = Configure.get_accessor
        end
        assert_not_equal "alternative setting", @config["test_setting"]
      end
    end
  end
end