# -*- coding: utf-8 -*-
require $RECORDER_ROOT_PATH + '/module/single_process.rb'
require $RECORDER_ROOT_PATH + '/module/polling_thread.rb'

module Recorder
  class TaskManager < SingleProcess
    # ポーリング時間間隔[sec](デフォルトは30秒)
    POLLING_TIME = 30

    # タスク処理用のスレッドを生成
    def initialize
      @poller = PollingThread.new(POLLING_TIME) do
          task.process while task = Task.next
      end
    end
  end
end