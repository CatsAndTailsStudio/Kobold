# frozen_string_literal: true

require "tty-config"
require 'fileutils'
require 'git'

#require_relative "Kobold/vars.rb"

module Kobold
  class << self
    def invoke
      Kobold.first_time_setup if !File.directory? "#{KOBOLD_DIR}/repo_cache"
      if !File.file? "#{Dir.pwd}/.kobold"
        puts "ERROR: Kobold file not found at '#{Dir.pwd}'"
        return
      end
      settings = Kobold.read_config(Dir.pwd)

      #puts Kobold::FORMAT_VERSION + " " + settings["kobold_config"]["format_version"]
      if Kobold::FORMAT_VERSION == settings["_kobold_config"]["format_version"]
        #settings.delete "kobold_config"

        # iterate over all dependencies
        settings.each do |key, value|
          if Kobold::CONFIG_TITLES.include? key
            #puts "skipping #{key}"
            next
          end
          repo_dir = "#{KOBOLD_DIR}/repo_cache/#{key.gsub('/', '-')}"

          source_repo = nil;
          # check if source exists
          if !Dir.exist? "#{repo_dir}/source" # TODO: make this properly check for git repo
            # if it doesnt, make it
            FileUtils.mkdir_p "#{repo_dir}/source"
            FileUtils.mkdir_p "#{repo_dir}/worktrees"
            FileUtils.mkdir_p "#{repo_dir}/branches" # these are also worktrees, but just for the branch specifically if possible. TODO for later
            #puts "#{value["source"]}/#{key}.git", "#{repo_dir}/source"
            source_repo = Git.clone "#{value["source"]}/#{key}.git", "#{repo_dir}/source"
          else
            source_repo = Git.open("#{repo_dir}/source")
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
                #if value["commit"].is_a? Float
                #  value["commit"] = value["commit"].to_i.to_s
                #end
                commit_val = value["commit"].to_s.delete_prefix('"').delete_suffix('"').delete_prefix("'").delete_suffix("'")
                if commit_val == 'latest'
                  # TODO just use source git repo
                  target_symlink = "#{repo_dir}/source"
                elsif commit_sha
                  commit_sha = source_repo.object(commit_val).sha;
                  target_symlink = "#{repo_dir}/worktrees/#{commit_sha}"
                  if !Dir.exist? target_symlink
                    # make it
                    source_repo.worktree(target_symlink, commit_sha).add
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
            #puts "value: " + value["dir"] + key.split('/').last
            #puts !File.symlink?(value["dir"] + key.split('/').last)

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

        # iterate over all sub kobold files
        sub_kobolds = if settings["_kobold_include"] then settings["_kobold_include"]["files"].strip.split("\n") else [] end
        sub_kobolds.each do |path|
          Dir.chdir(path.strip) do
            invoke
          end
        end

      else
        raise "Wrong format version"
      end
    end
  end
end
