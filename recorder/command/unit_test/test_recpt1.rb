# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module Recorder
  module UnitTest
    # テスト用ライブラリをロード
    require "test/unit"
    require $RECORDER_ROOT_PATH + '/unit_test/lib/test_unit_extensions'

    # テスト対象をロード
    require $RECORDER_ROOT_PATH + '/command/recpt1.rb'

    # テスト
    class  Recpt1Test < Test::Unit::TestCase
      NHK  = 27
      NHKE = 26

      def setup
        @log = Array.new
        @recpt1 = Recpt1.new("recpt1", "recpt1ctl", @log)
      end

      must "normal 5min record" do
        File.delete("test1.ts") if File.exist?("test1.ts")
        before_start_time = Time.now
        res = @recpt1.rec("--b25 --strip", NHK, 5, "test1.ts") do
          @log << "END FLAG"
        end
        assert_equal true, res
        assert_equal true, @recpt1.now_recording?
        assert_equal true, before_start_time <= @recpt1.get_started_time
        assert_not_equal nil, @recpt1.get_process_id
        assert_not_equal nil, @recpt1.get_cn
        sleep(1) until @recpt1.finished?
        assert_equal true, 4 <= @recpt1.get_recorded_length && @recpt1.get_recorded_length <= 6
        assert_equal true, @log.size > 5
        assert_equal "END FLAG", @log.last
        assert_equal true, File.exist?("test1.ts")
        File.delete("test1.ts")
      end

      must "ctl extend 5 + 5" do
        File.delete("test2.ts") if File.exist?("test2.ts")
        res = @recpt1.rec("--b25 --strip", NHK, 5, "test2.ts")
        assert_equal true, res
        assert_equal true, @recpt1.now_recording?
        @recpt1.ctl_extend(5)
        sleep(1) until @recpt1.finished?
        assert_equal true, 9 <= @recpt1.get_recorded_length && @recpt1.get_recorded_length <= 11
        assert_equal true, File.exist?("test2.ts")
        File.delete("test2.ts")
      end

      must "ctl time 5 + 5" do
        File.delete("test3.ts") if File.exist?("test3.ts")
        res = @recpt1.rec("--b25 --strip", NHK, 5, "test3.ts")
        assert_equal true, res
        assert_equal true, @recpt1.now_recording?
        @recpt1.ctl_time(10)
        sleep(1) until @recpt1.finished?
        assert_equal true, 9 <= @recpt1.get_recorded_length && @recpt1.get_recorded_length <= 11
        assert_equal true, File.exist?("test3.ts")
        File.delete("test3.ts")
      end

      must "ctl channel 5 + 5" do
        File.delete("test4.ts") if File.exist?("test4.ts")
        res = @recpt1.rec("--b25 --strip", NHK, 10, "test4.ts")
        assert_equal true, res
        assert_equal true, @recpt1.now_recording?
        sleep(5)
        @recpt1.ctl_channel(NHKE)
        sleep(1) until @recpt1.finished?
        assert_equal true, 9 <= @recpt1.get_recorded_length && @recpt1.get_recorded_length <= 11
        assert_equal true, File.exist?("test4.ts")
        File.delete("test4.ts")
      end
    end
  end
end