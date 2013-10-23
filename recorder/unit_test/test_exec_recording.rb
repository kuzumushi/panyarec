# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.dirname(File.expand_path(File.dirname(__FILE__)))

module Recorder
  module UnitTest
    # テスト用ライブラリをロード
    require "test/unit"
    require $RECORDER_ROOT_PATH + '/unit_test/lib/test_unit_extensions'

    # テスト対象をロード
    require $RECORDER_ROOT_PATH + '/exec_recording.rb'

    # テスト
    class  ExecRecordingTest < Test::Unit::TestCase
      TEST_DB_NAME = "test_ruby_recorder"
      NHK = 27

      def setup
        DataBase::Connection.specify_dbname(TEST_DB_NAME)
        DataBase::Connection.instance.drop_database
        Configure.init_configuration
        $config = Configure.get_accessor
      end

      must "normal 10 sec rec" do
        file_path = File.expand_path(File.dirname(__FILE__)) + "/test.ts"
        File.delete(file_path) if File.exist?(file_path)

        s = Time.now + 5
        e = s + 10
        reservation = Reservation.reserve(s..e, NHK, file_path, :terrestrial) do
          set_program_epg_flag
        end

        recording = ExecRecording.new(reservation)
        sleep(1) until recording.finished?

        assert_equal 1, Recorded.size
        recorded = Recorded.find.first
        assert_equal true, recorded.program_epg?
        assert_equal true, 9 <= recorded.get_recorded_length && recorded.get_recorded_length <= 11

        File.delete(file_path)
      end

      must "range change happen" do
        file_path = File.expand_path(File.dirname(__FILE__)) + "/test.ts"
        File.delete(file_path) if File.exist?(file_path)

        s = Time.now
        e = s + 10
        reservation = Reservation.reserve(s..e, NHK, file_path, :terrestrial)

        recording = ExecRecording.new(reservation)

        sleep(3)
        assert_equal true, Reservation.reserve_change(reservation, s..(e-5), nil)
        assert_equal s..(e-5), reservation.get_range
        sleep(1) until recording.finished?

        sleep(1)
        recorded = Recorded.find.first
        assert_equal true, 4 <= recorded.get_recorded_length && recorded.get_recorded_length <= 6

        File.delete(file_path)
      end
    end
  end
end