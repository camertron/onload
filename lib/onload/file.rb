# frozen_string_literal: true

module Onload
  class File
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def write(ignore_file: nil)
      source = ::File.read(path)

      ::File.extname(path).scan(/\.\w+/).each do |ext|
        source = Onload.processors[ext].call(source)
      end

      ::File.write(outfile, source).tap do
        if ignore_file
          ignore_file.add(outfile)
        elsif Onload.config.ignore_path
          ignore_file = IgnoreFile.load(Onload.config.ignore_path)
          ignore_file.add(outfile)
          ignore_file.persist!
        end
      end
    end

    def outfile
      @outfile ||= begin
        base_name = "#{Onload.basename(path)}.rb"
        ::File.join(::File.dirname(path), base_name)
      end
    end
  end
end
