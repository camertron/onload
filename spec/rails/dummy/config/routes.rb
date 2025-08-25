Rails.application.routes.draw do
  root to: "home#index"
  get "/action_list", to: "home#action_list"
end
