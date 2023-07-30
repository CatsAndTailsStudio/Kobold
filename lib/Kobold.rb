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

      puts Kobold::FORMAT_VERSION + " " + settings["kobold_config"]["format_version"]
      if Kobold::FORMAT_VERSION == settings["kobold_config"]["format_version"]
        settings.delete "kobold_config"

        # iterate over all dependencies
        settings.each do |key, value|
          puts "key:#{key}"
          repo_dir = "#{KOBOLD_DIR}/repo_cache/#{key.gsub('/', '-')}"

          master_repo = nil;
          # check if master exists
          if !Dir.exist? "#{repo_dir}/master" # TODO: make this properly check for git repo
            # if it doesnt, make it
            FileUtils.mkdir_p "#{repo_dir}/master"
            FileUtils.mkdir_p "#{repo_dir}/worktrees"
            puts "#{value["source"]}/#{key}.git", "#{repo_dir}/master"
            master_repo = Git.clone "#{value["source"]}/#{key}.git", "#{repo_dir}/master"
          else
            master_repo = Git.open("#{repo_dir}/master")
          end

          target_symlink = nil
          # check if requested version exists
          if value["tag"]
            dir_name = value["tag"].to_s.gsub("/","-")
            # TODO make the thing
          else # use hash as name
            if value["commit"]
              # use given commit name, also check it exists
              begin # git errors when it does not find the hash
                if value["commit"].is_a? Float
                  value["commit"] = value["commit"].to_i.to_s
                end
                commit_sha = master_repo.object(value["commit"].to_s.delete_prefix('"').delete_suffix('"').delete_prefix("'").delete_suffix("'")).sha;
                if commit_sha
                  target_symlink = "#{repo_dir}/worktrees/#{commit_sha}"
                  if !Dir.exist? target_symlink
                    # make it
                    master_repo.worktree(target_symlink, commit_sha).add
                  end
                else
                  raise "Cannot find commit"
                end
              rescue # we catch this error here
                raise "Cannot find commit"
              end
            else
              raise "No commit given for #{key}"
            end
          end

          # build the symlink
          if value["dir"].end_with? "/"
            FileUtils.mkdir_p value["dir"]
            File.symlink target_symlink, "#{value['dir']}/#{key.split('/').last}" if !File.exist? target_symlink

          else
            dir_components = value["dir"].split "/"
            dir_components.pop
            dir_components = dir_components.join "/"
            FileUtils.mkdir_p dir_components
            File.symlink target_symlink, value["dir"] if !File.exist? target_symlink
          end

        end

      else
        raise "Wrong format version"
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
      kobold_config.set "kobold_config", "format_version", value: Kobold::FORMAT_VERSION
      kobold_config.write
      File.rename ".kobold.ini", ".kobold"
    end
  end
end
