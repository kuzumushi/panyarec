# -*- coding: utf-8 -*-
module Recorder
  # コマンドに渡す引数(オプション)を保持するクラス
  class CommandOption
    private_class_method :new

    def self.convert_from_array(option_array)
      new(option_array)
    end

    def self.create(&block)
      option_setter = OptionSetter.new
      option_setter.instance_eval(&block)
      new(option_setter.get)
    end

    def initialize(option_array)
      @options = option_array
    end

    def to_a
      return @options
    end

    def to_s
      @options.flatten.join(" ")
    end

    class OptionSetter
      def set(option_name, *value)
        @options ||= Array.new
        @options << [option_name] + value
      end

      def get
        return @options
      end
    end
  end
end