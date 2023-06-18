# frozen_string_literal: true

require "rails/spec_helper"

describe HomeController, type: :request do
  describe "#index" do
    it "transpiles the file" do
      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.body).to(
        have_selector("div", text: "HELLO")
      )
    end

    it "allows hot reloading" do
      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.body).to(
        have_selector("div", text: "HELLO")
      )

      new_contents = <<~RUBY
        class Hello
          def hello
            "goodbye"
          end
        end
      RUBY

      with_file_contents(File.join(Onload::TestHelpers.fixtures_path, "hello.rb.up"), new_contents) do
        get "/"

        expect(response).to have_http_status(:ok)
        expect(response.body).to(
          have_selector("div", text: "GOODBYE")
        )
      end
    end
  end
end
