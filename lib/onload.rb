# frozen_string_literal: true

module Onload
  autoload :File, "onload/file"

  class << self
    attr_accessor :enabled
    alias enabled? enabled

    def register(extension, processor_klass)
      processors[extension] = processor_klass
    end

    def install!
      if Kernel.const_defined?(:Rails)
        require "onload/railtie"

        if Rails.respond_to?(:autoloaders) && Rails.autoloaders.zeitwerk_enabled?
          require "onload/core_ext/kernel_zeitwerk"
          require "onload/ext/zeitwerk/loader"
        else
          require "onload/core_ext/kernel"
          require "onload/ext/activesupport/dependencies"
        end
      else
        begin
          require "zeitwerk"
        rescue LoadError
          require "onload/core_ext/kernel"
        else
          require "onload/core_ext/kernel_zeitwerk"
          require "onload/ext/zeitwerk/loader"
        end
      end

      begin
        require "bootsnap"
      rescue LoadError
      else
        require "onload/ext/bootsnap/autoload"
      end
    end

    def process?(path)
      each_extension.any? { |ext| path.end_with?(ext) }
    end

    def each_extension
      return to_enum(__method__) unless block_given?

      processors.each { |ext, _| yield ext }
    end

    def unprocessed_file_for(file)
      base_name = basename(file)

      unprocessed_files_in(::File.dirname(file)).each do |existing_file|
        if basename(existing_file) == base_name
          return existing_file
        end
      end

      nil
    end

    def unprocessed_files_in(path)
      path_cache[path] ||= begin
        Dir.glob(::File.join(path, glob))
      end
    end

    def processors
      @processors ||= {}
    end

    def basename(file)
      basename = ::File.basename(file)

      if (idx = basename.index("."))
        return basename[0...idx]
      end

      basename
    end

    def disable
      old_enabled = enabled?
      self.enabled = false
      yield
    ensure
      self.enabled = old_enabled
    end

    def enable
      old_enabled = enabled?
      self.enabled = true
      yield
    ensure
      self.enabled = old_enabled
    end

    def glob
      @glob ||= "*{#{each_extension.to_a.join(",")}}"
    end

    private

    def path_cache
      @path_cache ||= {}
    end
  end

  self.enabled = true
end

if Kernel.const_defined?(:Rails)
  require "onload/railtie"
end
