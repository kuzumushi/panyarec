# -*- coding: utf-8 -*-
module Recorder
  class B25
    def initialize(b25_path)
      @b25_path = b25_path
    end

    def descramble(src_path, dest_path)
      `#{@b25_path} #{src_path} #{dest_path}`
    end
  end
end