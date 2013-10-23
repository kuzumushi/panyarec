# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module Recorder
  module UnitTest
    require "test/unit"
    require $RECORDER_ROOT_PATH + '/unit_test/lib/test_unit_extensions'


    require $RECORDER_ROOT_PATH + '/data_in_database/program_category.rb'

    class  ProgramCategoryTest < Test::Unit::TestCase
      TEST_DB_NAME = "test_ruby_recorder"

      def setup
        DataBase::Connection.specify_dbname(TEST_DB_NAME)
        ProgramCategory.delete_all
      end

      must "receive" do
        program_epg = Object.new
        def program_epg.get_large_categories
          return ["large_cat1", "large_cat2", "large_cat3", "large_cat2"]
        end
        def program_epg.get_middle_categories
          return ["middle_cat1", "middle_cat2", "middle_cat3", "middle_cat3"]
        end
        assert_equal 6, ProgramCategory.receive(program_epg).size
        assert_equal 6, ProgramCategory.size
        
        program_epg2 = Object.new
        def program_epg2.get_large_categories
          return ["large_cat1", "large_cat4"]
        end
        def program_epg2.get_middle_categories
          return ["middle_cat1", "middle_cat4"]
        end
        assert_equal 4, ProgramCategory.receive(program_epg2).size
        assert_equal 8, ProgramCategory.size
      end
    end
  end
end
