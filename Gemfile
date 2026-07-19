source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.4"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Redis for caching, jobs, and Action Cable
gem "redis", "~> 5.0"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem "letter_opener"
end

gem "discard", "~> 1.4"

gem "aws-sdk-s3", "~> 1.215"

gem "foreman", "~> 0.90.0"

gem "anthropic", "~> 1.23"

gem "dotenv-rails", "~> 3.1"
gem "rack-attack", "~> 6.7"

gem "premailer-rails", "~> 1.12"

# Authentication & Authorization
gem "devise", "~> 5.0"
gem "devise_invitable", "~> 2.0"
gem "pundit", "~> 2.3"
gem "rolify", "~> 6.0"

# Background jobs
gem "connection_pool", "~> 2.5"
gem "sidekiq", "~> 7.0"
gem "sidekiq-cron", "~> 1.12"

# Pagination
gem "pagy", "~> 9.0"

# Date grouping for queries
gem "groupdate", "~> 6.4"
gem "ahoy_email", "~> 2.0"

gem "hashids", "~> 1.0"

# Excel parsing for user imports
gem "creek", "~> 2.6"

gem "rss", "~> 0.3.3"
