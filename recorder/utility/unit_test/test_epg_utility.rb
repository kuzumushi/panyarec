# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module Recorder
  module UnitTest
    require 'json'

    # テスト用ライブラリをロード
    require "test/unit"
    require $RECORDER_ROOT_PATH + '/unit_test/lib/test_unit_extensions'

    # テスト対象をロード
    require $RECORDER_ROOT_PATH + '/utility/epg_utility.rb'

    # テスト
    class  EpgUtilityTest < Test::Unit::TestCase
      TEST_DB_NAME = "test_ruby_recorder"

      def setup
        DataBase::Connection.specify_dbname(TEST_DB_NAME)
        DataBase::Connection.instance.drop_database
        Configure.init_configuration
        $config = Configure.get_accessor
      end

      must "register channel epg" do
        # test_json_file is included.
        test_json_file_path = File.expand_path(File.dirname(__FILE__)) + "/test.json"
        assert_equal true, File.exist?(test_json_file_path)

        epg_hash = JSON.load(File.open(test_json_file_path, &:read))
        epg_collection = Epgdump::EpgCollection.new(epg_hash, 211)

        assert_nothing_raised do
          Utility::EpgUtility.register_channel_epg(epg_collection)
        end
        assert_equal Enumerator.new(epg_collection, :each_channel).count, Channel.size
      end

      must "register program epg" do
        # test_json_file is included.
        test_json_file_path = File.expand_path(File.dirname(__FILE__)) + "/test.json"
        assert_equal true, File.exist?(test_json_file_path)

        epg_hash = JSON.load(File.open(test_json_file_path, &:read))
        epg_collection = Epgdump::EpgCollection.new(epg_hash, 211)

        c = 0
        epg_collection.each_channel do |channel_epg|
          c += 1
          Channel.make_channel(channel_epg.get_cid, channel_epg.get_physical_channel, channel_epg.get_classification_symbol, channel_epg.to_h)
        end
        assert_equal c, Channel.size

        assert_nothing_raised do
          Utility::EpgUtility.register_program_epg(epg_collection)
        end
        assert_equal Program.size, epg_collection.count
      end

      must "update from recorded" do
        # test ts file is not included. please prepare somethong.
        ts_file = File.expand_path(File.dirname(__FILE__)) + "/test.ts"
        break unless File.exist?(ts_file)

        recorded = Recorded.new_recorded(0, ts_file, 0, Time.now, "0.0")
        recorded.call_recording_finished(10, {}, {})
        recorded.set_epg_flag(true, true)

        assert_nothing_raised do
          Utility::EpgUtility.update_from_recorded([recorded])
        end
        assert_equal true, Channel.size >= 1
        assert_equal true, Program.size >= 1
      end
    end
  end
end