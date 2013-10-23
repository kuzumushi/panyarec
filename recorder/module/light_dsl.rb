# -*- coding: utf-8 -*-
module Recorder
  module LightDSL
    def init
      @initialized = true
      @definitions = Array.new
    end

    def define_type(name, &block)
      init unless @initialized
      setting = Setting.new(name)
      setting.instance_eval(&block)
      @definitions.push(setting)
    end

    def pull_value(args, throw_exception=true, &block)
      matched_setting = @definitions.find do |setting|
        setting.instance_eval(&block)
      end
      unless matched_setting
        raise "no definition matched." if throw_exception
        return nil
      end
      return matched_setting.instance_exec(*args, &matched_setting.value_function)
    end

    def each_definition(&block)
      @definitions.each do |setting|
        setting.instance_eval(&block)
      end
    end

    class Setting
      def initialize(name)
        @name = name
      end

      def value(&block)
        @value_function = block
      end

      attr_reader :value_function
    end
  end
end
