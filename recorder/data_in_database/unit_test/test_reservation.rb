# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module Recorder
  module UnitTest
    # テスト用ライブラリをロード
    require "test/unit"
    require $RECORDER_ROOT_PATH + '/unit_test/lib/test_unit_extensions'

    # テスト対象をロード
    require $RECORDER_ROOT_PATH + '/data_in_database/reservation.rb'

    # テスト
    class  ReservationTest < Test::Unit::TestCase
      TEST_DB_NAME = "test_ruby_recorder"

      def setup
        DataBase::Connection.specify_dbname(TEST_DB_NAME)
        Reservation.delete_all
      end

      must "not overlap reserve 5" do
        origin_time = Time.now
        5.times do |i|
          start_time = origin_time + i
          res = Reservation.reserve(start_time..(start_time + 1), i, "#{i}.ts", :terrestrial, "", 2)
          assert_not_equal false, res
        end
        assert_equal 5, Reservation.size
      end

      must "overlap reserve 1" do
        assert_equal 0, Reservation.size
        ot = Time.now
        r1 = [(ot+ 0)..(ot+10), 1, "1.ts", :terrestrial, "", 2]
        r2 = [(ot+ 5)..(ot+15), 2, "2.ts", :terrestrial, "", 2]
        r3 = [(ot+10)..(ot+20), 3, "3.ts", :terrestrial, "", 2]
        r4 = [(ot+15)..(ot+25), 4, "4.ts", :terrestrial, "", 2]
        [r1, r2, r3, r4].each do |r|
          assert_not_equal false, Reservation.reserve(*r)
        end
        assert_equal 4, Reservation.size
      end

      must "overlap reserve 2" do
        assert_equal 0, Reservation.size
        ot = Time.now
        r0 = [(ot+ 0)..(ot+25), 0, "0.ts", :terrestrial, "", 2]
        r1 = [(ot+ 0)..(ot+10), 1, "1.ts", :terrestrial, "", 2]
        r2 = [(ot+ 5)..(ot+15), 2, "2.ts", :terrestrial, "", 2]
        r3 = [(ot+10)..(ot+20), 3, "3.ts", :terrestrial, "", 2]
        r4 = [(ot+15)..(ot+25), 4, "4.ts", :terrestrial, "", 2]

        assert_not_equal false, Reservation.reserve(*r0)
        assert_not_equal false, Reservation.reserve(*r1)
        assert_equal     false, Reservation.reserve(*r2)
        assert_not_equal false, Reservation.reserve(*r3)
        assert_equal     false, Reservation.reserve(*r4)
        assert_equal 3, Reservation.size
      end

      must "different type reserve" do
        assert_equal 0, Reservation.size
        ot = Time.now
        r0 = [(ot+ 0)..(ot+25), 0, "0.ts", :terrestrial, "", 2]
        r1 = [(ot+ 0)..(ot+25), 1, "1.ts", :terrestrial, "", 2]
        r2 = [(ot+ 0)..(ot+25), 2, "2.ts", :satellite,   "", 2]
        r3 = [(ot+ 0)..(ot+25), 3, "3.ts", :satellite,   "", 2]
        r4 = [(ot+ 0)..(ot+25), 4, "4.ts", :terrestrial, "", 2]

        assert_not_equal false, Reservation.reserve(*r0)
        assert_not_equal false, Reservation.reserve(*r1)
        assert_not_equal false, Reservation.reserve(*r2)
        assert_not_equal false, Reservation.reserve(*r3)
        assert_equal     false, Reservation.reserve(*r4)
        assert_equal 4, Reservation.size
      end

      must "same filename reserve" do
        assert_equal 0, Reservation.size
        ot = Time.now
        r0 = [(ot+ 0)..(ot+25), 0, "same.ts", :terrestrial, "", 2]
        r1 = [(ot+ 0)..(ot+25), 1, "same.ts", :satellite,   "", 2]

        assert_not_equal false, Reservation.reserve(*r0)
        assert_equal     false, Reservation.reserve(*r1)
        assert_equal 1, Reservation.size
      end

      must "destination file already exists" do
        range = (Time.now)..(Time.now + 100)
        this_file = File.expand_path(__FILE__)
        assert_equal true, File.exist?(this_file)
        assert_equal false, Reservation.reserve(range, 1, this_file, :terrestrial, "", 2)

        unexist_file = this_file + ".UNEXISTFILE"
        assert_equal false, File.exist?(unexist_file)
        assert_not_equal false, Reservation.reserve(range, 1, unexist_file, :terrestrial, "", 2)
      end

      must "nil file path is valid" do
        assert_equal 0, Reservation.size
        ot = Time.now
        r1 = Reservation.reserve((ot+ 0)..(ot+10), 1, nil, :terrestrial, "", 2)
        r2 = Reservation.reserve((ot+ 0)..(ot+10), 2, nil, :terrestrial, "", 2)
        assert_equal 2, Reservation.size
      end

      must "reservable? except ids" do
        assert_equal 0, Reservation.size
        ot = Time.now
        r1 = Reservation.reserve((ot+ 0)..(ot+10), 1, "1.ts", :terrestrial, "", 2)
        r2 = Reservation.reserve((ot+ 0)..(ot+10), 2, "2.ts", :terrestrial, "", 2)
        r3 = Reservation.reserve((ot+10)..(ot+20), 3, "3.ts", :terrestrial, "", 2)
        r4 = Reservation.reserve((ot+10)..(ot+20), 4, "4.ts", :terrestrial, "", 2)
        assert_equal 4, Reservation.size

        check1 = [(ot+00)..(ot+20), "check.ts", :terrestrial, [r1.id], "", 2]
        assert_equal false, Reservation.reservable?(*check1)

        check2 = [(ot+00)..(ot+20), "check.ts", :terrestrial, [r1.id, r2.id], "", 2]
        assert_equal false, Reservation.reservable?(*check2)

        check3 = [(ot+00)..(ot+20), "check.ts", :terrestrial, [r1.id, r3.id], "", 2]
        assert_equal true, Reservation.reservable?(*check3)
      end

      must "reserve change" do
        assert_equal 0, Reservation.size
        ot = Time.now
        r1 = Reservation.reserve((ot+ 0)..(ot+10), 1, "1.ts", :terrestrial, "", 2)
        r2 = Reservation.reserve((ot+ 0)..(ot+10), 2, "2.ts", :terrestrial, "", 2)
        r3 = Reservation.reserve((ot+10)..(ot+20), 3, "3.ts", :terrestrial, "", 2)
        assert_equal 3, Reservation.size

        assert_equal     false, Reservation.reserve_change(r3, (ot+05)..(ot+15), nil, "", 2)
        assert_not_equal false, Reservation.reserve_change(r2, (ot+05)..(ot+15), nil, "", 2)
        assert_equal     false, Reservation.reserve_change(r2, nil, "3.ts", "", 2)
      end

      must "safe_delete" do
        assert_equal 0, Reservation.size
        ot = Time.now
        r1 = Reservation.reserve((ot+ 0)..(ot+10), 1, "1.ts", :terrestrial, "", 2)
        r2 = Reservation.reserve((ot+ 0)..(ot+10), 2, "2.ts", :terrestrial, "", 2)
        r3 = Reservation.reserve((ot+10)..(ot+20), 3, "3.ts", :terrestrial, "", 2)
        assert_equal 3, Reservation.size

        Reservation.safe_delete(r1)
        assert_equal 2, Reservation.size
        assert_raise(RuntimeError) do
          r1.get_range
        end

        r2.write("started", true)
        Reservation.safe_delete(r2)
        assert_equal true, r2.read("specified_stop")

        r3.write("finished", true)
        assert_raise(RuntimeError) do
          Reservation.safe_delete(r3)
        end
      end

      must "next_reservation" do
        assert_equal 0, Reservation.size
        ot = Time.now
        r1 = Reservation.reserve((ot+ 0)..(ot+10), 1, "1.ts", :terrestrial, "", 2)
        r2 = Reservation.reserve((ot+ 5)..(ot+10), 2, "2.ts", :terrestrial, "", 2)
        r3 = Reservation.reserve((ot+10)..(ot+20), 3, "3.ts", :terrestrial, "", 2)
        assert_equal 3, Reservation.size

        assert_equal r1.id, Reservation.next_reservation.id
        assert_equal "1.ts", Reservation.next_reservation.read("file_path")
      end

      must "next_free_range" do
        assert_equal 0, Reservation.size
        ot = Time.now
        r1 = Reservation.reserve((ot+ 0)..(ot+10), 1, "1.ts", :terrestrial, "", 2)
        r2 = Reservation.reserve((ot+ 0)..(ot+ 4), 2, "2.ts", :terrestrial, "", 2)
        r3 = Reservation.reserve((ot+ 6)..(ot+ 8), 3, "3.ts", :terrestrial, "", 2)
        assert_equal 3, Reservation.size

        range1 = Reservation.next_free_range(2, :terrestrial, ot, 2)
        assert_equal 0, (ot+ 4) <=> range1.begin
        assert_equal 0, (ot+ 6) <=> range1.end

        range2 = Reservation.next_free_range(3, :terrestrial, ot, 2)
        assert_equal 0, (ot+ 8) <=> range2.begin
        assert_equal 0, (ot+11) <=> range2.end
      end

      must "recording_start_time?" do
        assert_equal 0, Reservation.size
        ot = Time.now
        r1 = Reservation.reserve((ot- 5)..(ot+ 0), 1, "1.ts", :terrestrial, "", 2)
        r2 = Reservation.reserve((ot+ 0)..(ot+ 5), 2, "2.ts", :terrestrial, "", 2)
        r3 = Reservation.reserve((ot+ 5)..(ot+10), 3, "3.ts", :terrestrial, "", 2)
        assert_equal 3, Reservation.size

        assert_equal true, r1.recording_start_time?(ot - r1.read("start_early").to_i)
        assert_equal true, r2.recording_start_time?(ot - r2.read("start_early").to_i)
        assert_equal false, r3.recording_start_time?(ot - r3.read("start_early").to_i)
      end

      must "get_X" do
        assert_equal 0, Reservation.size
        ot = Time.now
        r1 = Reservation.reserve((ot+ 0)..(ot+10), 1, "1.ts", :terrestrial, "", 2)
        assert_equal 1, Reservation.size

        assert_equal (ot+ 0)..(ot+10), r1.get_range
        assert_equal 1,                r1.get_physical_channel
        assert_equal "1.ts",           r1.get_file_path
        assert_equal :terrestrial,     r1.get_type_symbol
      end

      must "terrestrial? / satellite?" do
        assert_equal 0, Reservation.size
        ot = Time.now
        r1 = Reservation.reserve((ot+ 0)..(ot+10), 1, "1.ts", :terrestrial, "", 2)
        r2 = Reservation.reserve((ot+ 0)..(ot+10), 2, "2.ts", :satellite, "", 2)
        assert_equal 2, Reservation.size

        assert_equal true,  r1.terrestrial?
        assert_equal false, r1.satellite?
        assert_equal false, r2.terrestrial?
        assert_equal true,  r2.satellite?
      end

      must "make_recording_option_str" do
        assert_equal 0, Reservation.size
        ot = Time.now
        r1 = Reservation.reserve((ot+ 0)..(ot+10), 1, "1.ts", :terrestrial, "", 2)
        r2 = Reservation.reserve((ot+ 0)..(ot+10), 2, "2.ts", :terrestrial, "", 2) do
          set_udp("localhost", "1025")
        end
        assert_equal 2, Reservation.size
        assert_equal "--b25 --strip", r1.make_recording_option_str
        assert_equal "--b25 --strip --udp --addr localhost --port 1025", r2.make_recording_option_str
      end

      must "log" do
        assert_equal 0, Reservation.size
        ot = Time.now
        r1 = Reservation.reserve((ot+ 0)..(ot+10), 1, "1.ts", :terrestrial, "", 2)
        5.times do
          r1.log_push("hoge")
        end
        logger = r1.get_logger
        5.times do
          logger << "hoge"
        end
        assert_equal 10, r1.get_log.size
      end
    end
  end
end