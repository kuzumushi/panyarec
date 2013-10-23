# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module Recorder
  module UnitTest
    # テスト用ライブラリをロード
    require "test/unit"
    require $RECORDER_ROOT_PATH + '/unit_test/lib/test_unit_extensions'

    # テスト対象をロード
    require $RECORDER_ROOT_PATH + '/data_in_database/program.rb'

    # テスト
    class  ProgramTest < Test::Unit::TestCase
      TEST_DB_NAME = "test_ruby_recorder"

      def setup
        DataBase::Connection.specify_dbname(TEST_DB_NAME)
        Program.delete_all
      end

      must "new program" do
        assert_equal 0, Program.size
        s = Time.now
        e = s + 100
        program = Program.new_program(1, "c1", s..e, {}, :gr, [])
        assert_equal s..e, program.get_range
        assert_equal "c1", program.get_channel_id
        assert_nothing_raised do
          Program.new_program(2, "c1", s..e, {}, :gr, [])
        end
        assert_raise(RuntimeError) do
          Program.new_program(1, "c1", s..e, {}, :gr, [])
        end
      end

      must "update program" do
        assert_equal 0, Program.size
        s = Time.now
        e = s + 100
        p1  = Program.new_program(1, "c1", s..e, {}, :gr, [])
        assert_equal s..e, p1.get_range
        p1_ = Program.update_program(1, "c1", s+100..e+100, {}, :gr, [])
        assert_equal (s+100)..(e+100), p1_.get_range
        assert_raise(RuntimeError) do
          Program.update_program(2, "c1", s..e, {}, :gr, [])
        end
      end

      must "set program" do
        assert_equal 0, Program.size
        s = Time.now
        e = s + 100
        p1 = Program.new_program(1, "c1", s..e, {}, :gr, [])
        p2 = Program.set_program(1, "c1", s..e, {}, :gr, [])
        assert_equal p1.id, p2.id
        p3 = Program.set_program(2, "c1", s..e, {}, :gr, [])
        p3.write("event_id", 1)
        assert_raise(RuntimeError) do
          Program.set_program(1, "c1", s..e, {}, :gr, [])
        end
      end

      must "keyword search" do
        o = Time.now
        r1 = (o)..(o+100)
        r2 = (o+100)..(o+200)
        p1 = Program.new_program(1, "c1", r1, {"title" => "hoge", "detail" => "fuga piyo"}, :gr, [])
        p2 = Program.new_program(2, "c2", r2, {"title" => "fizz", "detail" => "buzz piyo"}, :bs, [])
        assert_equal 1, Program::Search.new("keyword" => "hoge").get_matched_number
        assert_equal 2, Program::Search.new("extend_keyword" => "piyo").get_matched_number
      end
    end
  end
end
