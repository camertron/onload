$:.unshift File.join(File.dirname(__FILE__), 'lib')
require "onload/version"

Gem::Specification.new do |s|
  s.name     = "onload"
  s.version  = ::Onload::VERSION
  s.authors  = ["Cameron Dutro"]
  s.email    = ["camertron@gmail.com"]
  s.homepage = "http://github.com/camertron/onload"
  s.description = s.summary = "A preprocessor system for Ruby."
  s.platform = Gem::Platform::RUBY

  s.require_path = "lib"

  s.files = Dir["{lib,spec}/**/*", "Gemfile", "LICENSE", "CHANGELOG.md", "README.md", "Rakefile", "onload.gemspec"]
end
