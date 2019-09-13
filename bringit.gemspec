# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'bringit/version'

Gem::Specification.new do |s|
  s.name        = 'bringit'
  s.version     = Bringit::VERSION
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.summary     = "Bringit library"
  s.description = "Bringit wrapper around git objects"
  s.authors     = ['Ontohub Core Developers', 'Dmitriy Zaporozhets']
  s.email       = ['ontohub-dev-l@ovgu.de', 'dmitriy.zaporozhets@gmail.com']
  s.license     = 'MIT'
  s.files       = `git ls-files lib/`.split("\n")
  s.homepage    =
    'https://github.com/ontohub/bringit'

  s.add_dependency('github-linguist', '>= 5.1', '< 6.2')
  s.add_dependency('activesupport', '>= 4.0')
  s.add_dependency('rugged', '>= 0.26', '< 0.28')
  s.add_dependency('charlock_holmes', '~> 0.7.3')

  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'bundler', '~> 1.14'
  s.add_development_dependency 'bundler-audit', '~> 0.6.0'
  s.add_development_dependency 'codecov', '~> 0.1.10'
  s.add_development_dependency 'factory_bot', '~> 4.8.2'
  s.add_development_dependency 'faker', '~> 2.3.0'
  s.add_development_dependency 'fuubar', '~> 2.3.0'
  s.add_development_dependency 'pry', '~> 0.11.0'
  s.add_development_dependency 'pry-byebug', '~> 3.6.0'
  s.add_development_dependency 'pry-rescue', '~> 1.4.4'
  s.add_development_dependency 'pry-stack_explorer', '~> 0.4.9.2'
  s.add_development_dependency 'rake', '~> 12.0'
  s.add_development_dependency 'rspec', '~> 3.7'
  s.add_development_dependency 'rubocop', '~> 0.52.1'
  s.add_development_dependency 'simplecov', '~> 0.16.1'
end
