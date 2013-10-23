# -*- coding: utf-8 -*-
$RECORDER_ROOT_PATH = File.expand_path(File.dirname(__FILE__))

require $RECORDER_ROOT_PATH + '/module/single_process.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/configure.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/log.rb'
require $RECORDER_ROOT_PATH + '/reservation_observer.rb'
require $RECORDER_ROOT_PATH + '/epg_updater.rb'
require $RECORDER_ROOT_PATH + '/http_server/http_server_main.rb'

module Recorder
  class RecorderMain < SingleProcess
    # レコーダーを初期化する。
    # ・DBコネクションと設定値をグローバルに定義する.。
    # ・各プロセス(機能)をスタートする。
    def initialize
      $config   = Configure.get_accessor
      @reservation_observer = ReservationObserver.start
      @epg_updater          = EpgUpdater.start
      Log << "プログラムが起動されました。"
    end

    # HTTPServerを立ち上げる
    # ・プロセスはhttpserver(sinatra)に移る(つまり処理は帰ってこない)
    def start_http_server
      UI::ServerMain.run! :host => 'localhost', :port => 9090
    end

    # 終了処理
    def finish
      Log << "プログラムの停止信号を受け取ったため、終了処理に入ります。"
      @reservation_observer.finish
      @epg_updater.finish
      Log << "プログラムは正常に終了しました。"
    end
  end
end
