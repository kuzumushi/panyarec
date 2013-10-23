# -*- coding: utf-8 -*-
module Recorder
  class Recpt1
    TIME_OUT = 15

    def initialize(recpt1_path, recpt1ctl_path, log=[])
      @recpt1_path = recpt1_path
      @recpt1ctl_path = recpt1ctl_path
      @log = log
    end

    # 録画開始
    # ・録画開始に成功したらtrueを返す(失敗したらfalse)。
    # ・ブロックを渡すと、録画終了時にそれを実行する(録画開始に失敗した場合は実行しない)。
    def rec(option_str, channel, rectime, destfile, &block)
      command = "#{@recpt1_path} #{option_str} #{channel} #{rectime.to_i || '-'} #{destfile || '-'}"
      @log << "$#{command}"
      @recpt1_out, writer = IO::pipe
      @spawn_process_id = Process::spawn(command, :err => writer, :out => writer)
      return false unless rec_start_succeeded?
      make_observe_thread(&block)
      return true
    end

    def finished?
      return @finished
    end

    def now_recording?
      return @succeeded && !@finished
    end

    def get_cn
      return @rec_singnal
    end

    def get_started_time
      return @started_time
    end

    def get_process_id
      return @process_id.to_i
    end

    def get_recorded_length
      return @recorded_length.to_i
    end

    def ctl_extend(extend_sec)
      @log << "//録画時間延長命令(+#{extend_sec.to_i})を送信。"
      `#{@recpt1ctl_path} --pid #{@process_id} --extend #{extend_sec.to_i}`
    end

    def ctl_time(length_sec)
      @log << "//総録画時間変更命令(#{length_sec.to_i})を送信。"
      `#{@recpt1ctl_path} --pid #{@process_id} --time #{length_sec.to_i}`
    end

    def ctl_channel(channel)
      @log << "//channel変更命令(#{@now_channel}=>#{channel})を送信。"
      `#{@recpt1ctl_path} --pid #{@process_id} --channel #{channel}`
    end

    def stop
      begin
        @log << "//recpt1-process:#{@process_id}(on #{@spawn_process_id})にSIGTERMを送信。"
        Process.kill(15, @process_id.to_i)
      rescue
        @log << "//失敗した模様。"
        return false
      end
      return true
    end

    private


    # 録画開始が成功したか判定。
    # ・C/N、process_id、started_timeを記録
    # ・判別不能な場合(recpt1の出力が来ない場合)は最大15秒でタイムアウトし、falseを返す
    def rec_start_succeeded?
      @process_id = nil
      succeeded = nil
      while IO::select([@recpt1_out], nil, nil, TIME_OUT)
        line = @recpt1_out.gets
        @log << line.chomp
        #pidの記述を見つけたらメモっておく
        @process_id = $1 if /pid = (\d+)/ =~ line
        #C/Nの記述を見つけたらメモっておく
        @rec_singnal = $1 if /C\/N = (.+)dB/ =~ line
        if /Recording/ =~ line then
          @log << "//「Recording」を見つけたので成功と判断。"
          succeeded = true
          break
        end
        if /Cannot tune/ =~ line then
          @log << "//「Cannot tune」を見つけたので失敗と判断。"
          succeeded = false
          break
        end
      end
      if succeeded.nil?
        @log << "//recpt1から#{TIME_OUT}秒応答がなかったのでタイムアウトします。"
        stop if @process_id
        succeeded = false
      end
      @started_time = Time.now
      return @succeeded = succeeded
    end

    def make_observe_thread(&block)
      Thread.new do
        while IO::select([@recpt1_out])
          line = @recpt1_out.gets
          @log << line.chomp
          #"Recorded 00sec"を見つけたら終了とみなす
          break if /Recorded (\d+)sec/ =~ line
        end
        @log << "//「Recorded XXsec」を見つけたので録画は終了とみなす。"
        @recorded_length = $1
        block.call if block
        @finished = true
      end
    end
  end
end
