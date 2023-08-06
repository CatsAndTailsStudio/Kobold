# frozen_string_literal: true

require "tty-config"
#require 'fileutils'

module Kobold
  class << self
    def read_config(dir)
      config = TTY::Config.new
      config.append_path dir
      settings = config.read ".kobold", format: :ini
      return settings
    end
  end
end
