# frozen_string_literal: true

require "tty-config"
require 'fileutils'
require 'git'

module Kobold
  class << self
    # create empty file with current
    # file version in current dir
    def init
      kobold_config = TTY::Config.new
      kobold_config.filename = ".kobold"
      kobold_config.extname = ".ini"
      kobold_config.set "kobold_config", "format_version", value: Kobold::FORMAT_VERSION
      kobold_config.write
      File.rename ".kobold.ini", ".kobold"
    end
  end
end
