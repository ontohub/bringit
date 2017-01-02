require 'simplecov'
SimpleCov.start

require 'gitlab_git'
require 'pry'

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |f| require f }

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
  config.include SeedHelper
  config.before(:all) { ensure_seeds }
end
