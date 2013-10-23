# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module Recorder
  module UnitTest
    # テスト用ライブラリをロード
    require "test/unit"
    require $RECORDER_ROOT_PATH + '/unit_test/lib/test_unit_extensions'

    # テスト対象をロード
    require $RECORDER_ROOT_PATH + '/data_in_database/channel.rb'

    # テスト
    class  ChannelTest < Test::Unit::TestCase
      TEST_DB_NAME = "test_ruby_recorder"

      def setup
        DataBase::Connection.specify_dbname(TEST_DB_NAME)
        Channel.delete_all
        Configure.init_configuration
        $config = Configure.get_accessor
      end

      must "make channel" do
        channel = Channel.make_channel("CID1", 27, :gr, {})
        assert_raise(RuntimeError) do
          Channel.make_channel("CID2", 27, :hoge, {})
        end
        assert_equal nil, Channel.make_channel("CID1", 27, :gr, {})
        assert_equal true, channel.active?
        assert_equal :terrestrial, channel.get_type_symbol
        assert_equal 27, channel.get_physical_channel
        assert_equal channel.id, Channel.find_by_channel_epg_id("CID1").id
      end

      must "X_all" do
        Channel.make_channel("CID1", 0, :gr, {})
        Channel.make_channel("CID2", 0, :gr, {})
        Channel.make_channel("CID3", 0, :bs, {})
        Channel.make_channel("CID4", 0, :bs, {})
        Channel.make_channel("CID5", 0, :cs, {})
        Channel.make_channel("CID6", 0, :cs, {})
        assert_equal 2, Channel.terrestrial_all.size
        assert_equal 4, Channel.satellite_all.size
        assert_equal 2, Channel.bs_all.size
        assert_equal 2, Channel.cs_all.size
      end

      must "X?" do
        c1 = Channel.make_channel("CID1", 0, :gr, {})
        c2 = Channel.make_channel("CID2", 0, :bs, {})
        c3 = Channel.make_channel("CID3", 0, :cs, {})
        assert_equal [true,  false, false, false], [c1.terrestrial?, c1.satellite?, c1.bs?, c1.cs?]
        assert_equal [false, true,  true,  false], [c2.terrestrial?, c2.satellite?, c2.bs?, c2.cs?]
        assert_equal [false, true,  false, true ], [c3.terrestrial?, c3.satellite?, c3.bs?, c3.cs?]
      end

      must "using for getting epg" do
        c1 = Channel.make_channel("CID1", 0, :gr, {})
        assert_equal false, c1.using_for_getting_epg?
        c1.set_using_for_getting_epg
        assert_equal true, c1.using_for_getting_epg?
      end
    end
  end
end