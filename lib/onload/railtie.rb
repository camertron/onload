# frozen_string_literal: true

require "rails/railtie"

module Onload
  class Railtie < Rails::Railtie
    initializer "onload.initialize", before: :set_autoload_paths do |app|
      Onload.install! if Onload.enabled?

      if Onload.enabled? && app.config.file_watcher
        paths = Set.new(app.config.eager_load_paths + app.config.autoload_paths)

        dirs = paths.each_with_object({}) do |path, ret|
          ret[path] = Onload.each_extension.map { |ext| ext.delete_prefix(".") }
        end

        app.reloaders << app.config.file_watcher.new([], dirs) do
          # empty block, watcher seems to need it?
        end
      end
    end

    rake_tasks do
      load ::File.expand_path(::File.join(*%w(. tasks transpile_rails.rake)), __dir__)
    end
  end
end
