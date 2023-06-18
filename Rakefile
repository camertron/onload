require "bundler"
require "rspec/core/rake_task"
require "rubygems/package_task"

require "onload"

Bundler::GemHelper.install_tasks

task default: :spec

task spec: ["spec:ruby", "spec:rails"]

desc "Run specs"
RSpec::Core::RakeTask.new("spec:ruby") do |t|
  t.pattern = "./spec/ruby/**/*_spec.rb"
end

desc "Run Rails specs"
RSpec::Core::RakeTask.new("spec:rails") do |t|
  t.pattern = "./spec/rails/**/*_spec.rb"
end
