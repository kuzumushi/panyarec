# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module Recorder
  module UnitTest
    # テスト用ライブラリをロード
    require "test/unit"
    require $RECORDER_ROOT_PATH + '/unit_test/lib/test_unit_extensions.rb'

    # テスト対象をロード
    require $RECORDER_ROOT_PATH + '/module/command_option.rb'

    # テスト
    class  CommandOptionTest < Test::Unit::TestCase

      def setup

      end

      must "use1" do
        command_option = CommandOption.create do
          set "--op1", "hoge"
          set "--op2", "fuga"
        end
        assert_equal "--op1 hoge --op2 fuga", command_option.to_s
      end

      must "use2" do
        command_option = CommandOption.create do
          set "--op1", "hoge1", "hoge2", "hoge3"
          set "--op2", ["--nested_op", "fuga1", "fuga2"]
        end
        assert_equal "--op1 hoge1 hoge2 hoge3 --op2 --nested_op fuga1 fuga2", command_option.to_s
      end

      must "convert" do
        convert_array = [["--op1", "hoge1", "hoge2"], ["--op2", ["--nested_op", "fuga1", "fuga2"]]]
        command_option = CommandOption.convert_from_array(convert_array)
        assert_equal "--op1 hoge1 hoge2 --op2 --nested_op fuga1 fuga2", command_option.to_s
      end

    end
  end
end