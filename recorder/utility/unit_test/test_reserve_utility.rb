# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module Recorder
  module UnitTest
    # テスト用ライブラリをロード
    require "test/unit"
    require $RECORDER_ROOT_PATH + '/unit_test/lib/test_unit_extensions'

    # テスト対象をロード
    require $RECORDER_ROOT_PATH + '/utility/reserve_utility.rb'

    # テスト
    class  ReserveUtilityTest < Test::Unit::TestCase
      TEST_DB_NAME = "test_ruby_recorder"

      def setup
        DataBase::Connection.specify_dbname(TEST_DB_NAME)
        DataBase::Connection.instance.drop_database
        Configure.init_configuration
        $config = Configure.get_accessor
      end

      must "reserve from program" do
        # make test channel
        channel = Channel.make_channel("EPG_ID_TEST", 27, :gr, {})
        # make test program
        s = Time.now + 5
        e = s + 100
        program = Program.set_program(1, channel.id, s, e, {})
        # reserve
        reservation = Utility::ReserveUtility.reserve_from_program(program)
        # assertions
        assert_equal program.id, reservation.get_option.get_program_id
        assert_equal s..e, reservation.get_range
        assert_equal 27, reservation.get_physical_channel
        assert_equal :terrestrial, reservation.get_type_symbol
      end

      must "reserve asap" do
        reservation = Utility::ReserveUtility.reserve_asap(10, 27, :terrestrial)
        s = Time.now
        t = s + 10
        range = reservation.get_range
        assert_equal true, s-1 <= range.begin && range.begin <= s+1
        assert_equal true, t-1 <= range.end && range.end <= t+1
      end

      must "reserve for program epg from channels" do
        # make test channel
        c1 = Channel.make_channel("EPG_ID_TEST1", 27, :gr, {})
        c2 = Channel.make_channel("EPG_ID_TEST2", 28, :gr, {})
        c3 = Channel.make_channel("EPG_ID_TEST3", 29, :gr, {})
        assert_equal 3, Channel.size

        Utility::ReserveUtility.reserve_for_program_epg_from_channels([c1, c2, c3])
        assert_equal 3, Reservation.size
        r1 = Reservation.find("physical_channel" => 27).first
        r2 = Reservation.find("physical_channel" => 28).first
        r3 = Reservation.find("physical_channel" => 29).first
        assert_equal r3.get_range.begin, [r1.get_range.end, r2.get_range.end].min
      end

      must "reserve_for_channel_epg" do
        Utility::ReserveUtility.reserve_for_channel_epg(:terrestrial, 10, [20, 21, 22])
        assert_equal 3, Reservation.size
      end

      must "reservation_update_as_program_updated" do
        # make test channel
        channel = Channel.make_channel("EPG_ID_TEST", 27, :gr, {})
        # make test program
        s = Time.now + 5
        e = s + 100
        program = Program.set_program(1, channel.id, s, e, {})
        # reserve
        reservation = Utility::ReserveUtility.reserve_from_program(program)
        assert_equal s..e, reservation.get_range

        # change program
        program = Program.set_program(1, channel.id, s+100, e+100, {})
        assert_not_equal ((s+100)..(e+100)), reservation.get_range
        Utility::ReserveUtility.reservation_update_as_program_updated
        assert_equal ((s+100)..(e+100)), reservation.get_range
      end
    end
  end
end