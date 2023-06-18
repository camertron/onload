# frozen_string_literal: true

require "active_support/dependencies"

module Onload
  module ActiveSupportDependenciesPatch
    # Allow activesupport to find unprocessed files.
    def search_for_file(path_suffix)
      autoload_paths.each do |root|
        path = ::File.join(root, path_suffix)
        unprocessed_path = Onload.unprocessed_file_for(path)
        return unprocessed_path if unprocessed_path
      end

      super
    end

    # For some reason, using autoload and a patched Kernel#load doesn't work
    # by itself for automatically loading unprocessed files. Due to what I can
    # only surmise is one of the side-effects of autoload, requiring any
    # unprocessed file that's been marked by autoload will result in a NameError,
    # i.e. Ruby reports the constant isn't defined. Pretty surprising considering
    # we're literally in the process of _defining_ that constant. The trick is to
    # essentially undo the autoload by removing the constant just before
    # loading the unprocessed file that defines it.
    def load_missing_constant(from_mod, const_name)
      if require_path = from_mod.autoload?(const_name)
        path = search_for_file(require_path)

        if path && Onload.process?(path)
          from_mod.send(:remove_const, const_name)
          require require_path
          return from_mod.const_get(const_name)
        end
      end

      super
    end
  end
end

module ActiveSupport
  module Dependencies
    class << self
      prepend Onload::ActiveSupportDependenciesPatch
    end
  end
end
