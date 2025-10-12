# frozen_string_literal: true

module Onload
  class Config
    attr_accessor :ignore_path

    def initialize
      @ignore_path = nil
    end

    def dup
      self.class.new.tap do |duplicate|
        duplicate.ignore_path = ignore_path.dup
      end
    end
  end
end
