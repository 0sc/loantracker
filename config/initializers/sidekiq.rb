require "sidekiq"

Sidekiq.configure_server do |config|
  config.redis = { url: ENV["REDISTOGO_URL"], size: 10 }
  config.average_scheduled_poll_interval = 10
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV["REDISTOGO_URL"], size: 10 }
end