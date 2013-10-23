# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module Recorder
  module UnitTest
    # テスト用ライブラリをロード
    require "test/unit"
    require $RECORDER_ROOT_PATH + '/unit_test/lib/test_unit_extensions'

    # テスト対象をロード
    require $RECORDER_ROOT_PATH + '/data_in_database/recorded.rb'

    # テスト
    class  RecordedTest < Test::Unit::TestCase
      TEST_DB_NAME = "test_ruby_recorder"

      def setup
        DataBase::Connection.specify_dbname(TEST_DB_NAME)
        Recorded.delete_all
      end

      must "new recorded" do
        s = Time.now
        r = Recorded.new_recorded(0, "test.ts", 27, s, "00.00")
        assert_equal false, r.finished?
        assert_equal 0,         r.get_reservation_id
        assert_equal "test.ts", r.get_file_path
        assert_equal 27,        r.get_physical_channel
        assert_equal s,         r.get_started_time
        assert_equal "00.00",   r.get_cn

        r.call_recording_finished(10, {"_id" => "r1"}, {"_id" => "p1"})
        assert_equal true, r.finished?
        assert_equal 10,   r.get_recorded_length
        assert_equal "r1", r.get_reservation_hash["_id"]
        assert_equal "p1", r.get_program_hash["_id"]

        File.open("test.ts", 'w', &Proc.new{})
        assert_equal true, r.file_exist?
        assert_equal true, r.completely_delete
      end

      must "epg flag" do
        assert_equal 0, Recorded.epg.size
        s = Time.now
        r1 = Recorded.new_recorded(0, "test.ts", 27, s, "00.00")
        r2 = Recorded.new_recorded(0, "test.ts", 27, s, "00.00")
        r3 = Recorded.new_recorded(0, "test.ts", 27, s, "00.00")
        r4 = Recorded.new_recorded(0, "test.ts", 27, s, "00.00")
        r5 = Recorded.new_recorded(0, "test.ts", 27, s, "00.00")
        r6 = Recorded.new_recorded(0, "test.ts", 27, s, "00.00")

        r3.call_recording_finished(0, {}, {})
        r4.call_recording_finished(0, {}, {})
        r5.call_recording_finished(0, {}, {})
        r6.call_recording_finished(0, {}, {})

        r2.set_epg_flag(true,  true)
        r3.set_epg_flag(true,  true)
        r4.set_epg_flag(true,  false)
        r5.set_epg_flag(false, false)

        assert_equal 2, Recorded.epg.size
        assert_equal 2, Recorded.epg.select{|r| r.program_epg?}.size
        assert_equal 1, Recorded.epg.select{|r| r.channel_epg?}.size
      end
    end
  end
end
