# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module Recorder
  module UnitTest
    # テスト用ライブラリをロード
    require "test/unit"
    require $RECORDER_ROOT_PATH + '/unit_test/lib/test_unit_extensions'

    # テスト対象をロード
    require $RECORDER_ROOT_PATH + '/module/tuner_entry.rb'

    # テスト
    class  SecureTunerTest < Test::Unit::TestCase
      TEST_DB_NAME = "test_ruby_recorder"

      def setup
        TunerEntry.init
      end

      must "secure" do
        assert_not_equal false, (t1 = TunerEntry.acquire(:terrestrial, 2, 0))
        assert_not_equal false, (t2 = TunerEntry.acquire(:terrestrial, 2, 0))
        assert_equal false, TunerEntry.acquire(:terrestrial, 2, 0)

        Thread.new do
          sleep(3)
          TunerEntry.release(t1)
        end
        assert_not_equal false, TunerEntry.acquire(:terrestrial, 2, 5)
      end
    end
  end
end