# -*- coding: utf-8 -*-
require $RECORDER_ROOT_PATH + '/data_in_database/data_in_database.rb'

module Recorder
  class ProgramSearchSet < DataInDataBase
    def self.add(search_hash)
      return create("search_hash" => search_hash)
    end

    def out
      return read("search_hash")
    end
  end
end
