# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{units2}
  s.version = '0.1.3'

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Daniel Mendler"]
  s.date = %q{2009-05-17}
  s.email = ["mail@daniel-mendler.de"]
  s.extra_rdoc_files = ["Manifest.txt"]
  s.files = ["lib/systems/time.yml", "lib/systems/imperial.yml", "lib/systems/si.yml", "lib/systems/misc.yml", "lib/systems/degree.yml", "lib/systems/scientific.yml", "lib/systems/binary.yml", "lib/units.rb", "Rakefile", "README.markdown", "test/test_unit.rb", "Manifest.txt"]
  s.has_rdoc = true
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{units}
  s.rubygems_version = %q{1.3.1}
  s.summary = 'Scientific unit support for ruby for calculations'
  s.homepage = %q{http://github.com/minad/units}
  s.test_files = ["spec/spec_units.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, [">= 1.8.3"])
    else
      s.add_dependency(%q<hoe>, [">= 1.8.3"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.8.3"])
  end
end
