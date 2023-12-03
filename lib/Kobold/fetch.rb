# frozen_string_literal: true

require "tty-config"
require 'fileutils'
require 'git'

#require_relative "Kobold/vars.rb"

module Kobold
  class << self
    def fetch
      Kobold.first_time_setup if !File.directory? "#{KOBOLD_DIR}/repo_cache"
      if !File.file? "#{Dir.pwd}/.kobold"
        puts "ERROR: Kobold file not found at '#{Dir.pwd}'"
        return
      end
      settings = Kobold.read_config(Dir.pwd)

      if Kobold::FORMAT_VERSION == settings["_kobold_config"]["format_version"]
        # iterate over all dependencies
        settings.each do |key, value|
          if key[0] == '_' 
            next
          end
          repo_dir = "#{KOBOLD_DIR}/repo_cache/#{value['repo'].gsub('/', '-')}"

          source_repo = nil;
          # check if source exists
          if !Dir.exist? "#{repo_dir}/source" # TODO: make this properly check for git repo
            # if it doesnt, make it
            FileUtils.mkdir_p "#{repo_dir}/source"
            FileUtils.mkdir_p "#{repo_dir}/worktrees"
            FileUtils.mkdir_p "#{repo_dir}/worktrees/branched"
            FileUtils.mkdir_p "#{repo_dir}/worktrees/sha"
            FileUtils.mkdir_p "#{repo_dir}/worktrees/labelled"
            FileUtils.mkdir_p "#{repo_dir}/branches"
            source_repo = clone_git_repo "#{value["source"]}/#{value['repo']}.git", "#{repo_dir}/source"
            next
            # TODO this may need to be reworked, might not fetch new branches that are required
            # if they havent been invoked previously.
            # works good enough for now :3
          else
            source_repo = Git.open("#{repo_dir}/source")
          end

          progress_bar = TTY::ProgressBar.new("[:bar] Fetching: #{value["source"]}/#{value['repo']}.git ", bar_format: :blade, total: nil, width: 45)

          thread = Thread.new(abort_on_exception: true) do
            source_repo.fetch(all: true)
          end
          progress_bar.start
          while thread.status
            progress_bar.advance
            sleep 0.016
          end
          puts
          #return thread.value
        end
      end
    end
  end
end
