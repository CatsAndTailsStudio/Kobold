# frozen_string_literal: true

require_relative "Kobold/version"
require "tty-config"
require 'fileutils'
require 'git'

module Kobold
  KOBOLD_DIR = "#{Dir.home}/.local/share/Kobold"
  class << self

    # read configuration file
    #   for each item:
    # 1. check if repo exists
    # ~2. check if correct version exists~
    # 3. check if symlink is correct
    def invoke
      first_time_setup if !File.directory? "#{KOBOLD_DIR}/repo_cache"
      config = TTY::Config.new
      config.append_path Dir.pwd
      settings = config.read ".kobold", format: :ini
      if Kobold::FILE_VERSION.equal? settings["kobold_config"]["format_version"]
        settings.delete "kobold_config"
        settings.each do |key, value|
          puts "key:#{key}"
          repo_dir = "#{KOBOLD_DIR}/repo_cache/#{key.gsub('/', '-')}"
          if !Dir.exist? "#{repo_dir}/master"
            FileUtils.mkdir_p "#{repo_dir}/master"
            puts "#{value["source"]}/#{key}.git", "#{repo_dir}/master"
            Git.clone "#{value["source"]}/#{key}.git", "#{repo_dir}/master"
          end
          if value["dir"].end_with? "/"
            FileUtils.mkdir_p value["dir"]
            File.symlink "#{repo_dir}/master", "#{value["dir"]}/#{key.split("/").last}" 
          else
            dir_components = value["dir"].split "/"
            dir_components.pop
            dir_components = dir_components.join "/"
            FileUtils.mkdir_p dir_components
            File.symlink "#{repo_dir}/master", value["dir"]
          end
        end
      else
        puts "Error: wrong format version"
      end
    end

    def first_time_setup
      FileUtils.mkdir_p "#{KOBOLD_DIR}/repo_cache"
    end

    # create empty file with current
    # file version in current dir
    def init
      kobold_config = TTY::Config.new
      kobold_config.filename = ".kobold"
      kobold_config.extname = ".ini"
      kobold_config.set "kobold_config", "format_version", value: Kobold::FILE_VERSION
      kobold_config.write
      File.rename ".kobold.ini", ".kobold"
    end
  end
end
