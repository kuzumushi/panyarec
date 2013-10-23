# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.dirname(File.expand_path(File.dirname(__FILE__)))

module Recorder
  module UnitTest
    # テスト用ライブラリをロード
    require "test/unit"
    require $RECORDER_ROOT_PATH + '/unit_test/lib/test_unit_extensions'

    # テスト対象をロード
    require $RECORDER_ROOT_PATH + '/epg_updater.rb'

    # テスト
    class  EpgUpdaterTest < Test::Unit::TestCase


      def setup
        Reservation.delete_all
        Configure.init_configuration
        $config = Configure.get_accessor
      end

    end
  end
end