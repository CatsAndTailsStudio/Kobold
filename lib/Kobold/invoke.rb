# frozen_string_literal: true

require "tty-config"
require 'fileutils'
require 'git'

module Kobold
  class << self
    def invoke
      Kobold.first_time_setup if !File.directory? "#{KOBOLD_DIR}/repo_cache"
      settings = Kobold.read_config(Dir.pwd)

      #puts Kobold::FORMAT_VERSION + " " + settings["kobold_config"]["format_version"]
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
            puts "value: " + value["dir"] + key.split('/').last
            puts !File.symlink?(value["dir"] + key.split('/').last)

            symlink1 = File.symlink?(value["dir"] + key.split('/').last)
            symlink2 = File.symlink? value["dir"]

            if !(symlink1 || symlink2)
              File.symlink(target_symlink, "#{value['dir']}/#{key.split('/').last}")
            end
            #File.symlink(target_symlink, "#{value['dir']}/#{key.split('/').last}")

          else
            dir_components = value["dir"].split "/"
            dir_components.pop
            dir_components = dir_components.join "/"
            FileUtils.mkdir_p dir_components
            File.symlink(target_symlink, value["dir"]) if !File.symlink? value["dir"]

            symlink1 = File.symlink?(value["dir"] + key.split('/').last)
            symlink2 = File.symlink? value["dir"]

            if !(symlink1 || symlink2)
              File.symlink(target_symlink, value["dir"])
            end
            #File.symlink(target_symlink, value["dir"])
          end

        end

      else
        raise "Wrong format version"
      end
    end
  end
end
