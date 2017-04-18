source 'https://rubygems.org'

gemspec

group :development do
  gem 'rspec', '~> 3.5.0'
  gem 'pry'
  gem 'rake'
end

group :test do
  gem 'ffaker', '~> 2.5.0'
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'bundler-audit', '~> 0.5.0', require: false
  gem "appraisal"
end
