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
          else
            source_repo = Git.open("#{repo_dir}/source")
          end

          # must be scoped here, used in various inner scopes
          target_symlink = nil

          #   Structure of a segment of following code:
          # if it declares a branch: make the branch
          # if it has a label
          #   it must have a sha
          #   if it has a branch
          #     use that branch + sha
          #   else
          #     use source + sha
          #   end
          # else check if it has a branch
          #   if it has a sha
          #     make the sha
          #   else
          #     make it point to branch
          #   end
          # else check if it has a sha
          #   make the sha on the source
          # else
          #   use source
          # end

          branch_repo = nil
          if value["branch"]
            branch_repo_path = "#{repo_dir}/branches/#{value["branch"]}"
            # check if branch already exists, make it if it doesnt
            if !Dir.exist? branch_repo_path
              FileUtils.mkdir_p "#{repo_dir}/branches"
              source_repo.worktree(branch_repo_path, value["branch"]).add
            end
            branch_repo = Git.open(branch_repo_path)
          end

          target_symlink = nil
          # if it has a label
          if value["label"]

            if !value["commit"]
              raise "Must give a specific sha when making a label. #{key} has no specific sha given"
            end
            if value["branch"]
              worktree_path = "#{repo_dir}/worktrees/labelled/#{value["label"]}/#{value["branch"]}"
              _commit_val = value["commit"].to_s.delete_prefix('"').delete_suffix('"').delete_prefix("'").delete_suffix("'")
              worktree_sha = branch_repo.object(_commit_val).sha;
              target_symlink = "#{worktree_path}/#{worktree_sha}"
              if !Dir.exist? target_symlink
                FileUtils.mkdir_p "#{worktree_path}"
                branch_repo.worktree(target_symlink, worktree_sha).add
              end
            else
              branch = source_repo.branch.name
              worktree_path = "#{repo_dir}/worktrees/labelled/#{value["label"]}/#{branch}"
              _commit_val = value["commit"].to_s.delete_prefix('"').delete_suffix('"').delete_prefix("'").delete_suffix("'")
              worktree_sha = source_repo.object(_commit_val).sha;
              target_symlink = "#{worktree_path}/#{worktree_sha}"
              if !Dir.exist? target_symlink
                FileUtils.mkdir_p "#{worktree_path}"
                source_repo.worktree(target_symlink, worktree_sha).add
              end
            end

          elsif value["branch"]

            if value['sha']
              worktree_path = "#{repo_dir}/worktrees/branched/#{branch}"
              _commit_val = value["commit"].to_s.delete_prefix('"').delete_suffix('"').delete_prefix("'").delete_suffix("'")
              worktree_sha = branch_repo.object(_commit_val).sha;
              target_symlink = "#{worktree_path}/#{worktree_sha}"
              if !Dir.exist? target_symlink
                FileUtils.mkdir_p "#{worktree_path}"
                branch_repo.worktree(target_symlink, worktree_sha).add
              end
            else
              target_symlink = "#{repo_dir}/branches/#{value['branch']}"
            end

          elsif value["commit"]

            worktree_path = "#{repo_dir}/worktrees/sha"
            _commit_val = value["commit"].to_s.delete_prefix('"').delete_suffix('"').delete_prefix("'").delete_suffix("'")
            worktree_sha = source_repo.object(_commit_val).sha;
            target_symlink = "#{worktree_path}/#{worktree_sha}"
            if !Dir.exist? target_symlink
              FileUtils.mkdir_p "#{worktree_path}"
              source_repo.worktree(target_symlink, worktree_sha).add
            end

          else

            target_symlink = "#{repo_dir}/source"

          end

          # build the symlink
          if value["dir"].end_with? "/"
            FileUtils.mkdir_p value["dir"]
            #puts "value: " + value["dir"] + key.split('/').last
            #puts !File.symlink?(value["dir"] + key.split('/').last)

            symlink1 = File.symlink?(value["dir"] + value['repo'].split('/').last)
            symlink2 = File.symlink? value["dir"]

            if !(symlink1 || symlink2)
              File.symlink(target_symlink, "#{value['dir']}/#{value['repo'].split('/').last}")
            end
            #File.symlink(target_symlink, "#{value['dir']}/#{key.split('/').last}")

          else
            dir_components = value["dir"].split "/"
            dir_components.pop
            dir_components = dir_components.join "/"
            FileUtils.mkdir_p dir_components
            File.symlink(target_symlink, value["dir"]) if !File.symlink? value["dir"]

            symlink1 = File.symlink?(value["dir"] + ['repo'].split('/').last)
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
      puts "Done!"
    end

    private

    def clone_git_repo(url, path)
      progress_bar = TTY::ProgressBar.new("[:bar] Cloning: #{url} ", bar_format: :blade, total: nil, width: 45)

      thread = Thread.new(abort_on_exception: true) do
        Git.clone url, path
      end
      progress_bar.start
      while thread.status
        progress_bar.advance
        sleep 0.016
      end
      puts
      return thread.value
    end
  end
end
