# -*- coding: utf-8 -*-
require $RECORDER_ROOT_PATH + '/module/single_process.rb'
require $RECORDER_ROOT_PATH + '/exec_recording.rb'
require $RECORDER_ROOT_PATH + '/module/polling_thread.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/reservation.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/log.rb'

module Recorder
  # Reservationクラスの保持する予約データを監視し、時間になったら録画を開始するクラス
  class ReservationObserver < SingleProcess
    # 録画開始チェックのポーリング時間間隔[sec](デフォルトは1秒)
    POLLING_TIME = 1

    def initialize
      @recordings = Array.new
      @poller = PollingThread.new(POLLING_TIME) do
        begin
          check
        rescue => error
          Log << error
        end
      end
    end

    def finish
      @recordings.each do |r|
        r.finish
      end
    end

    private

    def check
      while next_reservation = Reservation.next_reservation
        if next_reservation.finishing_in?(5)
          next_reservation.call_recording_missed
        elsif next_reservation.recording_start_time?(Time.now)
          @recordings << ExecRecording.new(next_reservation)
        end
      end
      @recordings.reject! do |r|
        r.finished?
      end
    end
  end
end

