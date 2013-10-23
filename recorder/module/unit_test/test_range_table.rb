# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module Recorder
  module UnitTest
    # テスト用ライブラリをロード
    require "test/unit"
    require $RECORDER_ROOT_PATH + '/unit_test/lib/test_unit_extensions'

    # テスト対象をロード
    require $RECORDER_ROOT_PATH + '/module/range_table.rb'

    # テスト
    class  RangeTableTest < Test::Unit::TestCase
      def setup
        @range_table = RangeTable.new
      end

      # get_max_overlap
      must "get max overlap test1" do
        # 0 1 2 3 4 5 6
        #  -----
        #    -----
        #      -----
        #        -
        #        -----
        [0..3, 1..4, 2..5, 3..4, 3..6].each do |range|
          @range_table.add(range)
        end
        assert_equal 4, @range_table.get_max_overlap
        assert_equal 1, @range_table.get_max_overlap(0..1)
        assert_equal 2, @range_table.get_max_overlap(4..6)
        assert_equal 4, @range_table.get_max_overlap(0..6)
      end

      must "get max overlap test2" do
        [0..10, 0..10, 0..10].each do |range|
          @range_table.add(range)
        end
        assert_equal 3, @range_table.get_max_overlap
        assert_equal 3, @range_table.get_max_overlap(3..7)
        assert_equal 3, @range_table.get_max_overlap(0..10)
        assert_equal 3, @range_table.get_max_overlap(0..5)
        assert_equal 3, @range_table.get_max_overlap(5..10)
        assert_equal 3, @range_table.get_max_overlap(-10..20)
        assert_equal 0, @range_table.get_max_overlap(10..20)
        assert_equal 0, @range_table.get_max_overlap(-10..0)
        assert_equal 0, @range_table.get_max_overlap(100..1000)
      end

      # remove_last
      must "remove last" do
        [0..1, 2..4, 1..3].each do |range|
          @range_table.add(range)
        end
        assert_equal 2, @range_table.get_max_overlap
        @range_table.remove_last
        assert_equal 1, @range_table.get_max_overlap
      end

      # next_range_begin
      must "next range begin test1" do
        [0..10, 0..1, 0..1, 2..10, 2..5, 6..7].each do |range|
          @range_table.add(range)
        end
        assert_equal 7, @range_table.next_range_begin(0, 3, 3)
      end

      must "next range begin test2" do
        [0..10, 0..10, 0..10].each do |range|
          @range_table.add(range)
        end
        assert_equal 10, @range_table.next_range_begin(0, 3, 3)
      end

      must "next range begin test3" do
        [0..10, 0..4, 6..8].each do |range|
          @range_table.add(range)
        end
        assert_equal 4, @range_table.next_range_begin(0, 2, 2)
        assert_equal 8, @range_table.next_range_begin(0, 3, 2)
      end

      must "none disturb" do
        [0..10].each do |range|
          @range_table.add(range)
        end
        assert_equal 0, @range_table.next_range_begin(0, 10, 2)
      end

      must "empty range table" do
        assert_equal 0, @range_table.next_range_begin(0, 10, 2)
      end

      must "so many range" do
        10000.times do |i|
          @range_table.add(i..(i+1))
        end
        assert_equal 10000, @range_table.next_range_begin(0, 10, 1)
      end

      # get_under
      must "get under test1" do
        [0..10, 0..1, 0..1, 2..10, 2..5, 6..7].each do |range|
          @range_table.add(range)
        end
        assert_equal [1..2, 5..6, 7..10] ,@range_table.get_under(3)
      end

      # range_joint
      must "range joint test1" do
        assert_equal [0..10], @range_table.range_joint([0..10, 4..6])
      end

      must "range joint test2" do
        assert_equal [0..10], @range_table.range_joint([0..5, 5..10])
      end

      must "range joint test3" do
        assert_equal [0..2, 3..5, 6..8], @range_table.range_joint([0..2, 3..5, 6..8])
      end

      # tail
      must "tail test1" do
        [0..10, 0..5, 6..9].each do |range|
          @range_table.add(range)
        end
        assert_equal 10, @range_table.tail
      end
    end
  end
end