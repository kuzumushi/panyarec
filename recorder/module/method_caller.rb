# -*- coding: utf-8 -*-
module Recorder
  class MethodCaller
    def initialize(object, &block)
      @object = object
      appender = Appender.new
      appender.instance_eval(&block)
      appender.get.each do |append_method_name, original_method_name|
        self.class.class_eval do
          define_method(append_method_name) do |*args|
            @object.send(original_method_name, *args)
          end
        end
      end
    end

    class Appender
      def append(append_method_name, original_method_name)
        @appends ||= Hash.new
        @appends[append_method_name] = original_method_name
      end

      def get
        return @appends
      end
    end
  end
end