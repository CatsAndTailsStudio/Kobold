# frozen_string_literal: true

module Kobold
  VERSION = "0.3.4"
  FORMAT_VERSION = "0.3.0"
  class << self
    def version
      puts "Kobold:        #{Kobold::VERSION}"
      puts "Kobold Format: #{Kobold::FORMAT_VERSION}"
    end
  end
end
