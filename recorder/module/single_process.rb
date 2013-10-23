# -*- coding: utf-8 -*-
module Recorder
  class SingleProcess
    private_class_method :new

    def self.start
      if @instance
        raise "Clsss #{self} can not make more than one instance."
      end
      return @instance = new
    end
  end
end