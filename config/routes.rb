require "sidekiq/web"

Rails.application.routes.draw do
  get "/callback", to: "tracker#verify"
  post "/callback", to: "tracker#callback"
  mount Sidekiq::Web => "/sidekiq"
end
