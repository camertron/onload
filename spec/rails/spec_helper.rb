# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "rails"
require "action_controller/railtie"

require_relative "../spec_setup"

Dir.chdir(File.expand_path("dummy", __dir__)) do
  require_relative File.join(*%w(dummy config application))
  Onload::DummyApplication.initialize!
end

require "rspec/rails"

module Onload
  module RailsTestHelpers
    def with_file_contents(path, contents)
      old_contents = ::File.read(path)
      ::File.write(path, contents)
      yield
    ensure
      ::File.write(path, old_contents)
    end
  end
end

RSpec.configure do |config|
  config.include(Onload::RailsTestHelpers)
  config.include(Capybara::RSpecMatchers, type: :request)
end
