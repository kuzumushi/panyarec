# -*- coding: utf-8 -*-
module Recorder
  class Task
    # タスクの登録
    def self.register()

    end

    # 次に実行するタスクを返す
    def self.next
      top = find.sort{|a, b| a["priority"] > b["priority"]}.sort{|a, b| a["set_time"] < b["set_time"]}.first
      return self.new(top)
    end

    # タスクの実行(同期処理)
    def process
    end
  end
end