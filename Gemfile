source 'https://rubygems.org'

ruby "2.3.1"
gem 'rails', '4.2.6'

gem 'rails-api'
gem 'faraday'

gem "puma"
gem "redis", "~> 3.3"
gem "sidekiq"
gem "sinatra", :require => false

group :development do
  gem 'spring'
  gem 'sqlite3'
end

group :production do
  gem "pg"
  gem "rails_12factor"
end



# To use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano', :group => :development

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'
