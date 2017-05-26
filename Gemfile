source 'https://rubygems.org'

gemspec

group :development do
  gem 'rspec', '~> 3.6.0'
  gem 'pry'
  gem 'rake'
end

group :test do
  gem 'factory_girl', '~> 4.8.0'
  gem 'faker', '~> 1.7.3'
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'bundler-audit', '~> 0.5.0', require: false
  gem "appraisal"
end
