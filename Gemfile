source 'https://rubygems.org'

gem 'rails', '~> 7.1.0'
gem 'pg', '~> 1.5'
gem 'puma', '~> 6.0'
gem 'sprockets-rails'
gem 'sassc-rails'
gem 'jquery-rails'
gem 'jquery-ui-rails', '~> 7.0'
gem 'jbuilder', '~> 2.11'

# Authentication & Authorization
gem 'devise', '~> 4.9'
gem 'cancancan', '~> 3.5'

# Admin
gem 'rails_admin', '~> 3.0'

# Models
gem 'paper_trail', '~> 15.0'
gem 'paranoia', '~> 2.6'
gem 'ancestry', '~> 4.3'
gem 'aasm', '~> 5.5'
gem 'active_importer'

# Forms & Views
gem 'simple_form', '~> 5.3'
gem 'bootstrap', '~> 5.3'
gem 'kaminari', '~> 1.2'
gem 'bootstrap5-kaminari-views'
gem 'select2-rails', '~> 4.0'
gem 'bootstrap-datepicker-rails'
gem 'momentjs-rails', '>= 2.9.0'

# Config & Utils
gem 'config'
gem 'rubyzip', '~> 2.3'
gem 'exception_notification', '~> 4.5'

# Background Jobs
gem 'sidekiq', '~> 7.0'
gem 'redis', '~> 5.0'

# 对象存储（S3 兼容，含 Cloudflare R2）。默认使用本地磁盘时不会被加载，
# 但必须在 bundle 内，否则 STORAGE_SERVICE=r2 会直接 Gem::LoadError。
gem 'aws-sdk-s3', require: false

group :development do
  gem 'web-console', '~> 4.2'
end

group :development, :test do
  gem 'byebug'
  gem 'annotate'
  gem 'dotenv-rails'
end

group :test do
  # Rails 7.0's test-unit integration (Rails::LineFiltering) is incompatible
  # with Minitest 6's changed Runnable#run signature; pin to the last 5.x
  # line so `bin/rails test` can run at all.
  gem 'minitest', '~> 5.25'
end
