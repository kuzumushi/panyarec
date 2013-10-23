# -*- coding: utf-8 -*-
module Recorder
  # 一定時間間隔で処理を行うポーリングスレッドを生成するクラス
  class PollingThread
    # コンストラクタ
    # ・ポーリング処理内容をブロックで渡す
    def initialize(interval_sec, &block)
      @cycle = true
      @thread = Thread.new do
        while sleep(interval_sec) && @cycle
          block.call
        end
      end
    end

    # 現在行っている処理を最後に、ポーリングを終了する
    def stop
      @cycle = false
    end

    # スレッドを強制的に終了させる
    def kill
      @thread.kill
    end

    def join
      @thread.join
    end
  end
end