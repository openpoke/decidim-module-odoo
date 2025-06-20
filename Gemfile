# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

# Inside the development app, the relative require has to be one level up, as
# the Gemfile is copied to the development_app folder (almost) as is.
base_path = ""
base_path = "../" if File.basename(__dir__) == "development_app"
require_relative "#{base_path}lib/decidim/odoo/version"

DECIDIM_VERSION = Decidim::Odoo::DECIDIM_VERSION

gem "decidim", DECIDIM_VERSION
gem "decidim-odoo", path: "."

gem "bootsnap", "~> 1.4"
gem "faker", "~> 2.14"
gem "uri", "~> 0.13.0" # URI 1.0 does not work well with Decidim 0.27

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri

  gem "decidim-dev", DECIDIM_VERSION
end

group :development do
  gem "letter_opener_web", "~> 1.3"
  gem "listen", "~> 3.1"
  gem "rubocop-faker", "~> 1.1"
  gem "spring", "~> 2.0"
  gem "spring-watcher-listen", "~> 2.0"
  gem "web-console", "~> 4.0"
end

group :test do
  gem "codecov", require: false
end
