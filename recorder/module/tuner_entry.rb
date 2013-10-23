# -*- coding: utf-8 -*-
module Recorder
  # チューナーの使用を管理するクラス。
  class TunerEntry
    private_class_method :new

    def self.init
      @initialized = true
      @tuners = Hash.new
      @mutex  = Mutex.new
    end

    def self.acquire(tuner_name, max_number, timeout_sec)
      init unless @initialized
      @tuners[tuner_name] ||= Array.new
      timeout_time = Time.now + timeout_sec
      loop do
        @mutex.synchronize do
          if @tuners[tuner_name].size < max_number
            tuner = new(tuner_name)
            @tuners[tuner_name].push(tuner)
            return tuner
          end
        end
        sleep(0.5)
        return false if Time.now >= timeout_time
      end
    end

    def self.release(tuner)
      raise "argument should be instance of #{self}." unless tuner.instance_of?(self)
      @mutex.synchronize do
        @tuners[tuner.tuner_name].reject! do |t|
          t == tuner
        end
        @released_time = Time.now
      end
    end

    def initialize(tuner_name)
      @tuner_name    = tuner_name
      @acquired_time = Time.now
      @released_time = nil
    end

    attr_reader   :tuner_name, :acquired_time
    attr_accessor :released_time
  end
end