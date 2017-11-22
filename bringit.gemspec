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
  s.authors     = ['Dmitriy Zaporozhets']
  s.email       = 'dmitriy.zaporozhets@gmail.com'
  s.license     = 'MIT'
  s.files       = `git ls-files lib/`.split("\n")
  s.homepage    =
    'https://github.com/ontohub/bringit'

  s.add_dependency('github-linguist', '>= 5.1', '< 5.4')
  s.add_dependency('activesupport', '>= 4.0')
  s.add_dependency('rugged', '~> 0.26.0')
  s.add_dependency('charlock_holmes', '~> 0.7.3')
end
