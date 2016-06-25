require "sidekiq/web"

Rails.application.routes.draw do
  post "/callback/", to: "verify#webhock"
  mount Sidekiq::Web => "/sidekiq"
end
