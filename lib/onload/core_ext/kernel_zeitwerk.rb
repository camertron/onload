# frozen_string_literal: true

require "zeitwerk"

module Kernel
  alias_method :onload_orig_require, :require
  alias_method :onload_orig_load, :load

  def load(file, *args)
    if Onload.process?(file) && Onload.enabled?
      f = Onload::File.new(file)
      f.write

      # I don't understand why, but it's necessary to delete the constant
      # in order to load the resulting file. Otherwise you get an error about
      # an uninitialized constant, and it's like... yeah, I _know_ it's
      # uninitialized, that's why I'm loading this file. Whatevs.
      loader = Zeitwerk::Registry.loader_for(file)
      parent, cname = loader.send(:autoloads)[file]

      if defined?(Zeitwerk::Cref) && parent.is_a?(Zeitwerk::Cref)
        parent.remove
      else
        parent.send(:remove_const, cname)
      end

      return onload_orig_load(f.outfile, *args)
    end

    onload_orig_load(file, *args)
  end

  def require(file)
    to_load = nil

    if File.absolute_path(file) == file
      to_load = Onload.unprocessed_file_for(file)
    elsif file.start_with?(".#{File::SEPARATOR}")
      abs_path = File.expand_path(file)
      to_load = Onload.unprocessed_file_for(abs_path)
    else
      $LOAD_PATH.each do |lp|
        check_path = File.expand_path(File.join(lp, file))

        if (unprocessed_file = Onload.unprocessed_file_for(check_path))
          to_load = unprocessed_file
          break
        end
      end
    end

    if !to_load || Onload::UNLOADABLE_EXTENSIONS.include?(::File.extname(to_load))
      # This will be either Ruby's original require or bootsnap's monkeypatched
      # require in setups that use bootsnap. Lord help us with all these layers
      # of patches.
      return onload_orig_require(file)
    end

    return false if $LOADED_FEATURES.include?(to_load)

    load to_load
    $LOADED_FEATURES << to_load

    return true
  end
end
