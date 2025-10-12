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

  it "adds an entry to the specified ignore file" do
    Onload.with_config(ignore_path: @ignore_path) do
      require "hello"
      ignore_file = Onload::IgnoreFile.load(@ignore_path)
      expect(ignore_file).to include("fixtures/hello.rb")
    end
  end
end
