require "logger"

module Onload
  class DummyApplication < ::Rails::Application
    if config.respond_to?(:load_defaults)
      config.load_defaults(
        Gem.loaded_specs['railties'].version.to_s.split('.')[0..1].join('.')
      )
    end

    config.eager_load = false

    config.autoload_paths << ::File.expand_path(
      ::File.join(*%w[.. .. .. fixtures]), __dir__
    )

    config.autoload_paths << Rails.root.join("lib").to_s
  end
end
