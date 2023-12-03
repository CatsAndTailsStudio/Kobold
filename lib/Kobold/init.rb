# frozen_string_literal: true

require "tty-config"
require 'fileutils'
require 'git'

module Kobold
  class << self
    # create empty file with current
    # file version in current dir
    def init
      kobold_default = <<-EOS
[_kobold_config]
format_version = #{Kobold::FORMAT_VERSION}

; must be unique, can be anything that doesnt start with underscore
;[raylib-linux]
;
; required
;repo = raysan5/raylib
;source = https://github.com
;
; optional, remove slash at the end to rename the dir the repo is in
;dir = external/linux-x64/
;
; one of these 2 is required
;branch = something
;commit = 'b8cd102'
;
; optional, makes unique trunk
;label = linux-x64
      EOS
      File.write('.kobold', kobold_default)
    end
  end
end
