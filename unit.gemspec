# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/lib/unit/version'
require 'date'

Gem::Specification.new do |s|
  s.name = 'unit'
  s.version = Unit::VERSION
  s.summary = 'Scientific unit support for ruby for calculations'
  s.homepage = 'http://github.com/minad/unit'
  s.license = 'MIT'

  s.authors = ['Daniel Mendler', 'Chris Cashwell']
  s.date  = Date.today.to_s
  s.email = ['mail@daniel-mendler.de']

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ['lib']

  s.add_development_dependency('rake', ['>= 0.8.7'])
  s.add_development_dependency('rspec')
end
