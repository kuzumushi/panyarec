# -*- coding: utf-8 -*-
require $RECORDER_ROOT_PATH + '/module/single_process.rb'
require $RECORDER_ROOT_PATH + '/module/polling_thread.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/reservation.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/recorded.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/log.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/configure.rb'
require $RECORDER_ROOT_PATH + '/utility/epg_utility.rb'
require $RECORDER_ROOT_PATH + '/utility/reserve_utility.rb'

module Recorder
  #EPGの次回更新時刻を監視し、時間になったらEPGの更新処理を開始するクラス
  class EpgUpdater < SingleProcess
    # ポーリング時間間隔[sec](デフォルトは30秒)
    POLLING_TIME = 30

    # 定期チェック用スレッドを生成。
    # ・チェック項目
    #   ・更新予定時刻を過ぎていたら、EPG用の録画予約を行う
    #   ・EPG用に録画された録画ファイルがあったら、EPGの抽出を行う
    def initialize
      @poller = PollingThread.new(POLLING_TIME) do
        begin
          reserve_for_update   if $config["epg_update?"] && time_to_update?
          update_from_recorded if Recorded.epg.size > 0
        rescue => error
          Log << error
        end
      end
    end

    def finish

    end

    private

    def time_to_update?
      return true unless @last_updated_time
      return @last_updated_time + $config["epg_interval"] <= Time.now
    end

    # 番組EPG更新用のTS録画を予約する。
    def reserve_for_update
      @last_updated_time = Time.now
      channels_for_epg = Channel.find.select{|c| c.using_for_getting_epg?}
      Utility::ReserveUtility::reserve_for_program_epg_from_channels(channels_for_epg)
      Log << "番組EPG更新用の録画予約を#{channels_for_epg.size}件行いました。"
    end

    # 録画済データの中にEPG更新用に録画されたものがあれば、EPG情報を抽出する。
    # ・EPGが更新された場合、番組予約の録画時刻のリフレッシュも行う。
    def update_from_recorded
      epg_recordeds = Recorded.epg
      Utility::EpgUtility::update_from_recorded(epg_recordeds)
      Utility::ReserveUtility::reservation_update_as_program_updated
      epg_recordeds.each do |r|
        r.completely_delete
      end
    end
  end
end
