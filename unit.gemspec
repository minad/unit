# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/lib/unit'

Gem::Specification.new do |s|
  s.name = %q{unit}
  s.version = Unit::VERSION

  s.authors = ["Daniel Mendler"]
  s.date = %q{2009-05-17}
  s.email = ["mail@daniel-mendler.de"]
  s.extra_rdoc_files = []

  s.files         = `git ls-files`.split("\n")
  s.require_paths = %w(lib)

  s.has_rdoc = true
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = s.name
  s.summary = 'Scientific unit support for ruby for calculations'
  s.homepage = %q{http://github.com/minad/si}

  s.add_development_dependency('bacon')
end
