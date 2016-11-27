source 'https://rubygems.org'

gemspec

group :development do
  gem 'rubocop', '~> 0.43.0'
  gem 'rubocop-rspec', '~> 1.8.0'
  gem 'coveralls', require: false
  gem 'rspec', '~> 3.0'
  gem 'rspec-mocks'
  gem 'rspec-its'
  gem 'webmock'
  gem 'guard'
  gem 'guard-rspec'
  gem 'pry'
  gem 'rake'
end

group :test do
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'bundler-audit', '~> 0.5.0', require: false
  gem "appraisal"
end
