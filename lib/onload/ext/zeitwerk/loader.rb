# frozen_string_literal: true

require "zeitwerk"
require "zeitwerk/loader"

module Onload
  module ZeitwerkLoaderPatch
    private

    def ruby?(path)
      super || Onload.process?(path)
    end

    if Zeitwerk::Loader.instance_method(:autoload_file).arity == 2
      def autoload_file(cref, file)
        if !Onload.process?(file)
          if (unprocessed_file = Onload.unprocessed_file_for(file))
            file = unprocessed_file
          end
        end

        super
      end
    else
      def autoload_file(parent, cname, file)
        if Onload.process?(file)
          # Some older versions of Zeitwerk very naïvely try to remove only the
          # last 3 characters in an attempt to strip off the .rb file extension,
          # while newer ones only remove it if it's actually there. This line is
          # necessary to remove the trailing leftover period for older versions,
          # and remove the entire extension for newer versions. Although cname
          # means "constant name," we use Onload.basename to remove all residual
          # file extensions that were left over from the conversion from a file
          # name to a cname.
          cname = Onload.basename(cname.to_s).to_sym
        else
          # if there is a corresponding unprocessed file, autoload it instead of
          # the .rb file
          if (unprocessed_file = Onload.unprocessed_file_for(file))
            file = unprocessed_file
          end
        end

        super
      end
    end

    # introduced in Zeitwerk v2.6.10
    def cname_for(basename, abspath)
      super(Onload.basename(basename), abspath)
    end
  end
end

module Zeitwerk
  class Loader
    prepend Onload::ZeitwerkLoaderPatch
  end
end
