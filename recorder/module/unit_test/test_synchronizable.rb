# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module Recorder
  module UnitTest
    # テスト用ライブラリをロード
    require "test/unit"
    require $RECORDER_ROOT_PATH + '/unit_test/lib/test_unit_extensions.rb'

    # テスト対象をロード
    require $RECORDER_ROOT_PATH + '/module/synchronizable.rb'

    # テスト
    class  InstanceSynchronizerTest < Test::Unit::TestCase

      class TestClass
        include Synchronizable
        @count = 0

        def self.init
          @count = 0
        end

        def self.increment(wait_time)
          tmp = @count + 1
          sleep(wait_time)
          @count = tmp
        end

        def self.count
          return @count
        end

        def initialize
          @count = 0
        end

        def increment(wait_time)
          tmp = @count + 1
          sleep(wait_time)
          @count = tmp
        end
        attr_reader :count
      end

      def setup
        TestClass.init
      end

      must "only class synchronize" do
        threads = Array.new
        20.times do
          threads << Thread.new do
            5.times do
              # note: if remove under synchronize block?
              TestClass.synchronize do
                TestClass.increment(0.001)
              end
            end
          end
        end
        threads.each do |thread|
          thread.join
        end
        assert_equal 100, TestClass.count
      end

      must "only one instance synchronize" do
        instance = TestClass.new
        threads = Array.new
        20.times do
          threads << Thread.new do
            5.times do
              # note: if remove under synchronize block?
              instance.synchronize do
                instance.increment(0.001)
              end
            end
          end
        end
        threads.each do |thread|
          thread.join
        end
        assert_equal 100, instance.count
      end

      must "exception in block don't generate deadlock." do
        instance = TestClass.new
        begin
          instance.synchronize do
            raise "error in block"
          end
        rescue
          instance.synchronize do
            instance.increment(0)
          end
        end
        assert_equal 1, instance.count
      end

      must "different instances don't lock each other" do
        threads = Array.new
        instance = TestClass.new
        (0..10).each do
          i = TestClass.new
          threads << Thread.new do
            i.synchronize do # note: if change i => instance ?
              10.times do
                i.increment(0.1)
              end
            end
          end
        end
        start_time = Time.now
        threads.each do |thread|
          thread.join
        end
        assert Time.now - start_time < 3.0
      end

      must "parent and children should lock each other" do
        puts ""
        i = Array.new
        t = Array.new
        t << Thread.new do
          i[0] = TestClass.new
          i[0].synchronize do
            print "[0-sync-start]"
            100.times do
              i[0].increment(0.01)
              print "[0]"
            end
            print "[0-sync-end]"
          end
        end
        sleep(0.1)
        t << Thread.new do
          i[1] = TestClass.new
          i[1].synchronize do
            print "[1-sync-start]"
            100.times do
              i[1].increment(0.01)
              TestClass.increment(0.01)
              print "[1]"
            end
            print "[1-sync-end]"
          end
        end
        sleep(0.1)
        t << Thread.new do
          TestClass.synchronize do
            print "[2-sync-start]"
            100.times do
              TestClass.increment(0.01)
              i[2].increment(0.01)
              print "[2]"
            end
            print "[2-sync-end]"
          end
        end
        sleep(0.1)
        t << Thread.new do
          i[2] = TestClass.new
          i[2].synchronize do
            print "[3-sync-start]"
            100.times do
              i[2].increment(0.01)
              TestClass.increment(0.01)
              print "[3]"
            end
            print "[3-sync-end]"
          end
        end
        sleep(0.1)
        t << Thread.new do
          i[3] = TestClass.new
          i[3].synchronize do
            print "[4-sync-start]"
            100.times do
              i[3].increment(0.01)
              print "[4]"
            end
            print "[4-sync-end]"
          end
        end
        t.each do |thread|
          thread.join
        end
        puts ""
        assert_equal 100, i[0].count
        assert_equal 100, i[1].count
        assert_equal 200, i[2].count
        assert_equal 100, i[3].count
        assert_equal 300, TestClass.count
      end
    end
  end
end