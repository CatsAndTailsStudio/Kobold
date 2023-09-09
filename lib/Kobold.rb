# frozen_string_literal: true

require_relative 'Kobold/version'
require 'tty-config'
require 'fileutils'
require 'git'
require 'tty-progressbar'

require_relative 'Kobold/read_config.rb'
require_relative 'Kobold/first_time_setup.rb'
require_relative 'Kobold/invoke.rb'
require_relative 'Kobold/init.rb'

module Kobold
  KOBOLD_DIR = "#{Dir.home}/.local/share/Kobold"
  class << self
  end
end
