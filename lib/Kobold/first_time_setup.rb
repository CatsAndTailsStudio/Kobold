# frozen_string_literal: true

require "tty-config"
require 'fileutils'
require 'git'

module Kobold
  class << self
    def first_time_setup
      FileUtils.mkdir_p "#{KOBOLD_DIR}/repo_cache"
    end
  end
end

