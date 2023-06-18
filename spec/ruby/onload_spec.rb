# frozen_string_literal: true

require "ruby/spec_helper"

describe Onload do
  it "transpiles a .up file" do
    require "hello"
    expect(Hello.new.hello).to eq("HELLO")
  end

  it "does not transpile when disabled" do
    Onload.disable do
      require "hello"
      expect(Hello.new.hello).to eq("hello")
    end
  end
end
