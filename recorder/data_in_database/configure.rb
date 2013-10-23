# -*- coding: utf-8 -*-
require $RECORDER_ROOT_PATH + '/data_in_database/data_in_database.rb'
require $RECORDER_ROOT_PATH + '/module/light_dsl.rb'

module Recorder
  # 環境設定管理クラス
  class Configure < DataInDataBase
    extend LightDSL

    private_class_method :new

    # accessorを取得
    def self.get_accessor
      unless @accessor
        init_configuration unless size == 1
        @accessor = find.first
      end
      return @accessor
    end

    # DB上にconfigureデータを新規作成する。
    # ・初期値はデフォルト設定ファイルで指定された値
    # ・すでにconfigureデータが存在する場合は削除される。
    def self.init_configuration
      delete_all
      default_setting = Hash.new
      each_definition do
        default_setting[@key] = @default
      end
      create(default_setting)
      @accessor = nil
    end

    # 値読み出し
    def [](key)
      return self.class.pull_value(read(key)) do
        @key == key
      end
    rescue
      raise "\"#{key}\" is undefined in configure."
    end

    #---------------------------------------------------------------
    # 設定項目定義
    #---------------------------------------------------------------

    define_type 'テスト用' do
      @key     = "test_setting"
      @desc    = ""
      @default = "hello"
      value do |val|
        val.to_s
      end
    end

    define_type 'recpt1コマンドパス' do
      @key     = "recpt1_path"
      @desc    = ""
      @default = "/usr/local/bin/recpt1"
      value do |val|
        val.to_s
      end
    end

    define_type 'recpt1ctlコマンドパス' do
      @key     = "recpt1ctl_path"
      @desc    = ""
      @default = "/usr/local/bin/recpt1ctl"
      value do |val|
        val.to_s
      end
    end

    define_type 'epgdump(Piro77氏版)コマンドパス' do
      @key     = "epgdump_path"
      @desc    = ""
      @default = "/usr/local/bin/epgdump"
      value do |val|
        val.to_s
      end
    end

    define_type '一時ファイル保存ディレクトリパス' do
      @key     = "tmp_dir_path"
      @desc    = ""
      @default = $RECORDER_ROOT_PATH + "/tmp/"
      value do |val|
        val.to_s
      end
    end

    define_type 'デフォルトでの録画ファイル保存ディレクトリパス' do
      @key     = "default_ts_dir"
      @desc    = ""
      @default = $RECORDER_ROOT_PATH + "/ts/"
      value do |val|
        val.to_s
      end
    end

    define_type 'レコーダーが使用する地上波チューナーの数' do
      @key     = "max_terrestrial_tuner_number"
      @desc    = "現在の録画予約最大重複数未満に本値を減らした場合、超過した分の録画は失敗するので注意。"
      @default = "2"
      value do |val|
        val.to_i
      end
    end

    define_type 'レコーダーが使用する衛星波チューナーの数' do
      @key     = "max_satellite_tuner_number"
      @desc    = "現在の録画予約最大重複数未満に本値を減らした場合、超過した分の録画は失敗するので注意。"
      @default = 2
      value do |val|
        val.to_i
      end
    end

    define_type '地上波放送の番組EPG取得のために録画するTSファイルの長さ(秒)' do
      @key     = "epg_record_length_terrestrial"
      @desc    = ""
      @default = "30"
      value do |val|
        val.to_i
      end
    end

    define_type '衛星波放送の番組EPG取得のために録画するTSファイルの長さ(秒)' do
      @key     = "epg_record_length_satellite"
      @desc    = ""
      @default = "60"
      value do |val|
        val.to_i
      end
    end

    define_type '予約時刻よりも早めに録画を開始する時間(秒)' do
      @key     = "recording_time_shift_ahead"
      @desc    = "コマンドの実行にかかる時間などを考え、指定秒だけ録画の開始を早める。" +
                 "直前に他の録画が存在し、それが邪魔をしている場合はその録画の終了時間も早める。"
      @default = "3"
      value do |val|
        val.to_i
      end
    end

    define_type 'チューナー確保のタイムアウト時間(秒)' do
      @key     = "tuner_secure_timeout_sec"
      @desc    = "録画開始時にチューナーが使用できる状態でなかった場合のタイムアウト時間。"
      @default = "10"
      value do |val|
        val.to_i
      end
    end

    define_type '番組EPGの自動更新を行うかどうか(true/false)' do
      @key     = "epg_update?"
      @desc    = "特に理由が無ければtrue。"
      @default = "true"
      value do |val|
        !!(/^true$/i =~ val.to_s)
      end
    end

    define_type '番組EPGの自動更新の間隔(秒)' do
      @key     = "epg_interval"
      @desc    = "1800秒(30分)～86400秒(1日)程度。"
      @default = "3600"
      value do |val|
        val.to_i
      end
    end

    define_type '' do
      @key     = "scan_terrestrial_channel_under"
      @desc    = ""
      @default = "13"
      value do |val|
        val.to_i
      end
    end

    define_type '' do
      @key     = "scan_terrestrial_channel_top"
      @desc    = ""
      @default = "62"
      value do |val|
        val.to_i
      end
    end

    define_type 'EPG取得用BSチャンネル' do
      @key     = "scan_bs_channel"
      @desc    = ""
      @default = "211"
      value do |val|
        val.to_s
      end
    end

    define_type 'EPG取得用CSチャンネル' do
      @key     = "scan_cs_channel"
      @desc    = ""
      @default = "CS20"
      value do |val|
        val.to_s
      end
    end

    define_type 'BSを視聴するかどうか(true/false)' do
      @key     = "bs_active?"
      @desc    = ""
      @default = "true"
      value do |val|
        !!(/^true$/i =~ val.to_s)
      end
    end

    define_type 'CSを視聴するかどうか(true/false)' do
      @key     = "cs_active?"
      @desc    = ""
      @default = "false"
      value do |val|
        !!(/^true$/i =~ val.to_s)
      end
    end
  end
end
