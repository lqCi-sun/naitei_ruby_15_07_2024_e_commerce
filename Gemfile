source "https://rubygems.org"
git_source(:github){|repo| "https://github.com/#{repo}.git"}

ruby "3.2.2"

gem "activerecord-import"
gem "active_storage_validations", "0.9.8"
gem "bcrypt", "3.1.18"
gem "bootsnap", require: false
gem "bootstrap-sass", "3.4.1"
gem "cancancan"
gem "config"
gem "devise"
gem "faker", "2.21.0"
gem "figaro"
gem "font-awesome-sass", "~> 6.0"
gem "image_processing", "1.12.2"
gem "importmap-rails"
gem "jbuilder"
gem "mysql2", "~> 0.5"
gem "pagy"
gem "paranoia", "~> 2.5"
gem "pry-rails"
gem "puma", "~> 5.0"
gem "rails", "~> 7.0.5"
gem "rails_config"
gem "ransack"
gem "sassc-rails"
gem "sidekiq"
gem "social-share-button"
gem "sprockets-rails"
gem "stimulus-rails"
gem "toastr-rails"
gem "turbo-rails"
gem "tzinfo-data", platforms: %i(mingw mswin x64_mingw jruby)

group :development, :test do
  gem "debug", platforms: %i(mri mingw x64_mingw)
  gem "rspec-rails", "~> 4.0.1"
  gem "rubocop", "~> 1.26", require: false
  gem "rubocop-checkstyle_formatter", require: false
  gem "rubocop-rails", "~> 2.14.0", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end
