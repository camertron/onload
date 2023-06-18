# frozen_string_literal: true

require 'set'

namespace :onload do
  task transpile: :environment do
    config = Rails.application.config
    paths = Set.new(config.autoload_paths + config.eager_load_paths)

    paths.each do |path|
      Dir.glob(File.join(path, "**", Onload.glob)).each do |file|
        f = Onload::File.new(file).tap(&:write)
        puts "Wrote #{f.outfile}"
      end
    end
  end
end
