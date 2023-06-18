# frozen_string_literal: true

namespace :onload do
  task :transpile do
    Dir.glob(File.join("**", Onload.glob)).each do |file|
      f = Onload::File.new(file).tap(&:write)
      puts "Wrote #{f.outfile}"
    end
  end
end
