# frozen_string_literal: true

module Onload
  module BootsnapAutoloadPatch
    def autoload(const, path)
      # Bootsnap monkeypatches Module.autoload in order to leverage its load
      # path cache, which effectively converts a relative path into an absolute
      # one without incurring the cost of searching the load path.
      # Unfortunately, if an unprocessed file has already been transpiled, the
      # cache seems to always return the corresponding .rb file. Bootsnap's
      # autoload patch passes the .rb file to Ruby's original autoload,
      # effectively wiping out the previous autoload that pointed to the
      # unprocessed file. To fix this we have to intercept the cache lookup and
      # force autoloading the unprocessed file if one exists.
      cached_path = Bootsnap::LoadPathCache.load_path_cache.find(path)

      if (unprocessed_path = Onload.unprocessed_file_for(cached_path))
        return autoload_without_bootsnap(const, unprocessed_path)
      end

      super
    end
  end
end

class Module
  prepend Onload::BootsnapAutoloadPatch
end
