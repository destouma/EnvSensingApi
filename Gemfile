source "https://rubygems.org"

gem "rails", "~> 8.1.4"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.6"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 8.0"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder", "~> 2.15"
# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Admin UI, served with Sprockets (dartsass-sprockets compiles its SCSS with Dart Sass)
gem "rails_admin", "~> 3.3"
gem "sprockets-rails", "~> 3.5"
gem "dartsass-sprockets", "~> 3.2"

gem "carrierwave", "~> 3.1"
gem "rack-attack", "~> 6.8"

# API docs served at /api-docs
gem "rswag-api", "~> 2.17"
gem "rswag-ui", "~> 2.17"
# Not a default gem since Ruby 4.0 and rswag-ui does not declare it
gem "ostruct"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  gem "rspec-rails", "~> 8.0"
  gem "rswag-specs", "~> 2.17"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Adds schema comments to models: bin/rails annotate_models
  gem "annotaterb"
end
