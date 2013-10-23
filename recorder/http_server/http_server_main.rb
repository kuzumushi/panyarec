# -*- coding: utf-8 -*-
require $RECORDER_ROOT_PATH + '/data_in_database/log.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/program_category.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/channel.rb'
require $RECORDER_ROOT_PATH + '/data_in_database/recorded.rb'
require $RECORDER_ROOT_PATH + '/utility/reserve_utility.rb'
require $RECORDER_ROOT_PATH + '/utility/ui_utility.rb'
require $RECORDER_ROOT_PATH + '/module/time_descriptor.rb'


module Recorder
  require 'sinatra/base'

  module UI
    class ServerMain < Sinatra::Base
      # sinatra設定
      set :environment, :production
      set :sessions, true
      set :views, $RECORDER_ROOT_PATH + '/http_server/template'
      set :public_dir, $RECORDER_ROOT_PATH + '/http_server/public'
      set :haml, :format => :html5

      not_found do
        "NOT FOUND"
      end


      #-----------------------------
      # HTML
      #-----------------------------

      # TOPページ(現在時刻における番組表)
      get '/' do
        @origin  = Time.now - 60*60*1
        @edge    = @origin  + 60*60*12
        @type    = "gr"
        @timed   = TimeDescriptor.new
        @title   = "PannyaRec"
        @channel = Channel.low_select({}, {:sort => {"order_number" => 1}}).select{|c| c.active? && c.classification_match?(@type)}
        @program = Program.low_select({"end" => {"$gt" => @origin}, "start" => {"$lt" => @edge}})
        @category_color_hash = ProgramCategory.make_color_hash("white")
        haml :top
      end

      # 新規設定ページ
      get '/new' do
        @title = "Welcome to PannyaRec"
        haml :new
      end

      # 環境設定ページ
      get '/setting' do
        @title = "環境設定 - PannyaRec"
        haml :setting
      end

      # チャンネル一覧ページ
      get '/channel' do
        @title = "チャンネル一覧 - PannyaRec"
        @channel = Channel.low_select.select{|c| c.active?}
        @program = Program.low_select
        haml :channel
      end

      # ログ一覧ページ
      get '/log' do
        @title = "ログ一覧 - PannyaRec"
        @log = Log.low_select({}, {:sort => {"time" => -1}})
        haml :log
      end

      # 予約一覧ページ
      get '/reservation' do
        @title = "予約一覧 - PannyaRec"
        @timed = TimeDescriptor.new
        @reservation = Reservation.low_select({}, {:sort => {"start" => 1}})
        haml :reservation
      end

      #-----------------------------
      # JSON
      #-----------------------------

      # チャンネルスキャン
      get '/json/channel_scan.json' do
        reserved_num = Utility::UIUtility.reserve_for_channel_scan
        content_type 'application/json'
        {:message => "チャンネルスキャン用に#{reserved_num}件の録画予約を行いました。完了までには通常数十分を要します。"}.to_json
      end

      # チャンネルスキャンプロセスカウント
      get '/json/channel_scan_get_process.json' do
        content_type 'application/json'
        {:rest_count => Reservation.find.select{|r| r.get_option.channel_epg?}.size}.to_json
      end

      # 番組予約
      get '/json/reserve/:program_id' do
        message = ""
        succeeded = Utility::UIUtility.try_reserve_from_program(params[:program_id], message)
        content_type 'application/json'
        {:error => !succeeded, :message => message}.to_json
      end

      # 現在時刻を取得
      get '/json/time.json' do
        content_type 'application/json'
        {:str => Time.now.getlocal.strftime("%Y/%m/%d %H:%M:%S")}.to_json
      end
      
      # 番組検索
      post '/json/program_search' do
        searched = Program::Search.new(params, params[:limit], params[:page])
        programs_hash = searched.next_program_map do |program|
          channel = Channel.new(program.get_channel_id)
          {
            :program_id     => program.id.to_s,
            :title          => program.get_program_epg.get_title,
            :channel_name   => "#{channel.get_channel_epg.get_name}",
            :start_time_str => TimeDescriptor.new.desc(program.get_start_time),
            :event_id       => program.get_event_id
          }
        end
        content_type 'application/json'
        {
          :limited_number   => programs_hash.size,
          :matched_number   => searched.get_matched_number,
          :now_page_number  => searched.get_now_page_number,
          :all_page_number  => searched.get_all_page_number,
          :programs         => programs_hash
        }.to_json
      end

      # 番組IDから番組情報を取得
      get '/json/program_info/:program_id' do
        message = ""
        program = Utility::UIUtility.get_program(params[:program_id], message)
        content_type 'application/json'
        unless program
          {:error_message => message}.to_json
        else
          channel = Channel.new(program.get_channel_id)
          {
            :title          => program.get_program_epg.get_title,
            :channel_name   => "#{channel.get_channel_epg.get_name}",
            :start_time_str => TimeDescriptor.new.desc(program.get_start_time),
            :event_id       => program.get_event_id,
            :detail         => program.get_program_epg.get_detail
          }.to_json
        end
      end
          
      # チャンネルの順序をスワップ
      post '/json/swap_channel_order' do
        result = Utility::UIUtility.swap_channel_order(params[:channel_id1], params[:channel_id2])
        content_type 'application/json'
        {:result => result}.to_json
      end

      # チャンネルを非アクティブ化
      post '/json/channel_non_active' do
        result = Utility::UIUtility.channel_switch_non_active(params[:channel_id])
        content_type 'application/json'
        {:result => result}.to_json
      end

      # カテゴリの一覧を取得
      get '/json/get_category_list' do
        categories = ProgramCategory.find.map do |category|
          {
            :category_id => category.id.to_s,
            :name        => category.get_name,
            :level       => category.get_level,
            :color       => category.get_color
          }
        end
        content_type 'application/json'
        {
          :number     => categories.size,
          :categories => categories
        }.to_json
      end

      # チャンネル一覧取得
      get '/json/get_channel_list' do
        channels = Channel.low_select.map do |channel|
          {
            :channel_id    => channel.id.to_s,
            :name          => channel.get_channel_epg.get_name
          }
        end
        content_type 'application/json'
        {
          :number   => channels.size,
          :channels => channels
        }.to_json
      end

      # 予約一覧取得
      get '/json/get_reservation_list' do
        reservations = Reservation.low_select.map do |reservation|
          {
            :reservation_id   => reservation.id.to_s,
            :physical_channel => reservation.get_physical_channel,
            :date             => TimeDescriptor.new.desc_range(reservation.get_range)
          }
        end
        content_type 'application/json'
        {
          :number       => reservations.size,
          :reservations => reservations
        }.to_json
      end

      # ログ一覧取得
      post '/json/get_log_list' do
        logs = Log.select_type(params[:type], params[:limit], params[:page]).map do |log|
          {
            :log_id   => log.id.to_s,
            :name     => log.get_name,
            :time     => TimeDescriptor.new.desc(log.get_time),
            :message  => log.get_message,
            :detail   => log.get_detail
          }
        end
        content_type 'application/json'
        {
          :matched_number => Log.type_size(params[:type]),
          :limited_number => logs.size,
          :logs           => logs
        }.to_json
      end

      # 録画済一覧取得
      post '/json/get_recorded_list' do
        searched_recordeds = Recorded::Search.new(params, params[:limit], params[:page])
        hashed_recordeds = searched_recordeds.map do |recorded|
          program_hash = recorded.get_program_hash
          {
            :recorded_id  => recorded.id.to_s,
            :started_time => TimeDescriptor.new.desc(recorded.read("started_time")),
            :title        => program_hash ? program_hash["program_epg"]["title"] : "-",
            :file_path    => recorded.get_file_path
          }
        end
        content_type 'application/json'
        {
          :matched_number => searched_recordeds.matched_size,
          :limited_number => params[:limit],
          :recordeds      => hashed_recordeds
        }.to_json
      end

      # カテゴリカラー設定
      post '/json/change_category_color' do
        result = Utility::UIUtility.change_category_color(params[:category_id], params[:color])
        content_type 'application/json'
        {:result => result}.to_json
      end

      #-----------------------------
      # CSS
      #-----------------------------

      # 共通CSS
      get '/stylesheets/main.css' do
        sass :'sass/main'
      end

      # トップページCSS
      get '/stylesheets/top.css' do
        sass :'sass/top'
      end

      #-----------------------------
      # ASX
      #-----------------------------

      # tsファイルアクセス
      get '/video/:recorded_id' do |recorded_id|
=begin
        print "Content-type: application/vnd.ms-asf; charset='utf-8'\n"
        print 'Content-Disposition: inline; filename="view.asx"' , "\n\n"
        
        print <<CON
<ASX version = "3.0">
<PARAM NAME = "Encoding" VALUE = "UTF-8" />
  <ENTRY>
    <REF HREF="#{url}" />
    <TITLE>#{recorded.get("Title")}</TITLE>
    <DURATION VALUE="#{recorded.file_length}" />
  </ENTRY>
</ASX>
CON
end
=end
      end
        
    end
  end
end
