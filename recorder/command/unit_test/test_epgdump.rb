# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module Recorder
  module UnitTest
    # テスト用ライブラリをロード
    require "test/unit"
    require $RECORDER_ROOT_PATH + '/unit_test/lib/test_unit_extensions'

    # テスト対象をロード
    require $RECORDER_ROOT_PATH + '/command/epgdump.rb'

    # 録画ファイル作成用
    require $RECORDER_ROOT_PATH + '/command/recpt1.rb'

    # テスト
    class  EpgdumpTest < Test::Unit::TestCase
      NHK = 27

      def setup
        @epgdump = Epgdump.new("epgdump", "./")
      end

      # should be after recpt1.rb test
      must "use" do
        ts_dest = "epgdump_test.ts"
        File.delete(ts_dest) if File.exist?(ts_dest)
        recpt1 = Recpt1.new("recpt1", "recpt1ctl", [])
        assert_equal true, recpt1.rec("--b25 --strip", NHK, 10, ts_dest)
        sleep(1) until recpt1.finished?
        # channel
        @epgdump.parse(ts_dest, NHK).each_channel do |channel_epg|
          assert_not_equal nil, channel_epg.get_name
          assert_equal :gr, channel_epg.get_classification_symbol
          assert_equal NHK, channel_epg.get_physical_channel
        end
        # program
        @epgdump.parse(ts_dest, NHK).each do |program_epg, channel_epg|
          assert_not_equal nil, program_epg.get_title
        end
        File.delete(ts_dest)
      end
    end
  end
end