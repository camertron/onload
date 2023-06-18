# frozen_string_literal: true

require "onload"

class UpcaseLoader
  def self.call(source)
    source.gsub(/(\"\w+\")/, '\1.upcase')
  end
end

Onload.register(".up", UpcaseLoader)

module Onload
  module TestHelpers
    def with_clean_env
      Onload.unprocessed_files_in(fixtures_path).each do |unprocessed_file|
        processed_file = Onload::File.new(unprocessed_file).outfile
        ::File.unlink(processed_file) if ::File.exist?(processed_file)
        $LOADED_FEATURES.delete(unprocessed_file)
      end

      yield
    end

    def fixtures_path
      ::File.expand_path(::File.join("fixtures"), __dir__)
    end

    extend(self)
  end
end

RSpec.configure do |config|
  config.extend(Onload::TestHelpers)

  config.around(:each) do |example|
    Onload::TestHelpers.with_clean_env { example.run }
  end
end

$:.push(Onload::TestHelpers.fixtures_path)
