# frozen_string_literal: true

require_relative "Kobold/version"

module Kobold
  class << self

    # read configuration file
    #   for each item:
    # 1. check if repo exists
    # ~2. check if correct version exists~
    # 3. check if symlink is correct
    def invoke

    end

    # create empty file with current
    # file version in current dir
    def init

    end
  end
end

puts "Kobold was included!!!"
