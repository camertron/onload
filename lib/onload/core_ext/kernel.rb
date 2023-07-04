# frozen_string_literal: true

module Onload
  module KernelLoadPatch
    def load(file, *args)
      # ActiveSupport::Dependencies adds an extra .rb to the end
      if Onload.process?(file.chomp('.rb'))
        file = file.chomp('.rb')
      end

      if Onload.process?(file) && Onload.enabled?
        f = Onload::File.new(file)
        f.write

        return super(f.outfile, *args)
      end

      super(file, *args)
    end
  end

  module KernelRequirePatch
    def require(file)
      # check to see if there's an unprocessed file somewhere on the load path
      to_load = nil

      if ::File.absolute_path(file) == file
        to_load = Onload.unprocessed_file_for(file)
      elsif file.start_with?(".#{::File::SEPARATOR}")
        abs_path = ::File.expand_path(file)
        to_load = Onload.unprocessed_file_for(abs_path)
      else
        [$LOAD_PATH[-1]].each do |lp|
          check_path = ::File.expand_path(::File.join(lp, file))

          if (unprocessed_file = Onload.unprocessed_file_for(check_path))
            to_load = unprocessed_file
            break
          end
        end
      end

      return super(file) unless to_load
      return super(file) if Onload::UNLOADABLE_EXTENSIONS.include?(::File.extname(to_load))
      return false if $LOADED_FEATURES.include?(to_load)

      # Must call the Kernel.load class method here because that's the one
      # activesupport doesn't mess with, and in fact the one activesupport
      # itself uses to actually load files. In case you were curious,
      # activesupport redefines Object#load and Object#require i.e. the
      # instance versions that get inherited by all other objects. Yeah,
      # it's pretty awful stuff. Although honestly we're not much better lol.
      Kernel.load(to_load)
      $LOADED_FEATURES << to_load

      return true
    end
  end
end

module Kernel
  class << self
    prepend Onload::KernelLoadPatch
  end
end

class Object
  prepend Onload::KernelRequirePatch
end
