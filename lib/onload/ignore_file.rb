# frozen_string_literal: true

require "set"

module Onload
  class MalformedIgnoreFileError < StandardError; end

  class IgnoreFile
    ONLOAD_SECTION_START = "##### ONLOAD BUILD ARTIFACTS (AUTO-GENERATED) #####"
    ONLOAD_SECTION_STOP  = "##### END ONLOAD BUILD ARTIFACTS #####"

    class << self
      def load(manifest_path)
        manifest_path = ::File.expand_path(manifest_path)
        lines = ::File.read(manifest_path).split(/\r?\n/)
        start_idx = lines.index(ONLOAD_SECTION_START)
        stop_idx = lines.index(ONLOAD_SECTION_STOP)

        # Start and stop indices should either both be numbers or both be nil.
        # Anything else, and something weird is going on.
        if start_idx.class != stop_idx.class
          raise MalformedIgnoreFileError, "the ignore file at #{manifest_path} appears to be malformed and onload doesn't know how to modify it"
        end

        ignored_paths = if start_idx && stop_idx
          lines[start_idx..stop_idx].map(&:strip)
        else
          []
        end

        ignored_paths.reject! do |path|
          path.empty? || path.start_with?("#")
        end

        new(manifest_path, Set.new(ignored_paths))
      end
    end

    attr_reader :manifest_path, :dirty

    alias dirty? dirty

    def initialize(manifest_path, ignored_paths)
      @manifest_path = manifest_path
      @ignored_paths = ignored_paths
      @dirty = false
    end

    def includes?(path)
      @ignored_paths.include?(path)
    end

    alias include? includes?

    def add(path)
      ignored_path = ::File.expand_path(path)
      ignored_path_segments = ignored_path.split(::File::SEPARATOR)

      if ignored_path_segments[0...manifest_dirname_segments.size] != manifest_dirname_segments
        raise "file to ignore #{path} is not relative to the specified ignore file at #{manifest_path}"
      end

      relative_ignored_path = ignored_path_segments[manifest_dirname_segments.size..-1].join(::File::SEPARATOR)
      @ignored_paths << relative_ignored_path

      @dirty = true

      nil
    end

    def persist!
      return unless dirty?

      lines = ::File.read(manifest_path).split(/\r?\n/)
      start_idx = lines.index(ONLOAD_SECTION_START)
      stop_idx = lines.index(ONLOAD_SECTION_STOP)

      if start_idx && stop_idx
        lines[start_idx..stop_idx] = [
          ONLOAD_SECTION_START,
          *@ignored_paths,
          ONLOAD_SECTION_STOP
        ]
      else
        lines += [
          "",
          ONLOAD_SECTION_START,
          *@ignored_paths,
          ONLOAD_SECTION_STOP,
          ""
        ]
      end

      contents = lines.join("\n")
      contents << "\n" unless contents.end_with?("\n")

      ::File.write(manifest_path, contents)

      @dirty = false
    end

    private

    def manifest_dirname
      @manifest_dirname ||= ::File.dirname(manifest_path)
    end

    def manifest_dirname_segments
      @manifest_diranme_segments ||= manifest_dirname.split(::File::SEPARATOR)
    end
  end
end
