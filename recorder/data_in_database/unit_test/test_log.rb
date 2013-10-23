# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module Recorder
  module UnitTest
    # テスト用ライブラリをロード
    require "test/unit"
    require $RECORDER_ROOT_PATH + '/unit_test/lib/test_unit_extensions'

    # テスト対象をロード
    require $RECORDER_ROOT_PATH + '/data_in_database/log.rb'

    # テスト
    class  LogTest < Test::Unit::TestCase
      TEST_DB_NAME = "test_ruby_recorder"

      def setup
        DataBase::Connection.specify_dbname(TEST_DB_NAME)
        Log.delete_all
        Configure.init_configuration
        $config = Configure.get_accessor
      end

      must "<<" do
        Log << "hoge"
        Log << ::StandardError.new("error hoge")
        assert_equal 2, Log.size
      end

      must "write" do
        Log.write(:error, ::RuntimeError.new("error hoge"))
        Log.write(:info, "hoge")
        Log.write(:tuner_use, "rid", "tname", Time.now, Time.now + 100)
        assert_equal 3, Log.size
      end

      must "not defined class" do
        assert_raise(RuntimeError) do
          Log << 100
        end
      end

      must "not defined type" do
        assert_raise(RuntimeError) do
          Log.write(:hoge, "hoge")
        end
      end

      must "pull data" do
        Log.write(:info, "hoge")
        log = Log.find.first
        assert_equal :info, log.read("type")
        assert_equal "動作報告", log.read("name")
        assert_equal "hoge", log.read("message")
        assert_equal "", log.read("detail")
      end
    end
  end
end