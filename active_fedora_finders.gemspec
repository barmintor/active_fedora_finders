# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "active_fedora_finders/version"

Gem::Specification.new do |s|
  s.name        = "active_fedora_finders"
  s.version     = ActiveFedora::Finders::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Benjamin Armintor"]
  s.email       = ["armintor@gmail.com"]
  s.homepage    = %q{https://github.com/barmintor/active_fedora_finders}
  s.summary     = %q{A library for adding ActiveRecord-style dynamic finders to ActiveFedora::Base subclasses.}
  s.description = %q{A mixin library for ActiveFedora. Generates dynamic finder methods operating against the FCRepo object search terms (DCES elements and object properties).}

  s.rubygems_version = %q{1.3.7}

  s.add_dependency('active-fedora', '>=4.2.0')
  s.add_dependency('nokogiri')
  s.add_dependency("activerecord", '~>3.2.0')
  s.add_dependency("activesupport", '~>3.2.0')
  s.add_dependency("rubydora", '~>0.5.9')
  s.add_development_dependency("yard")
  s.add_development_dependency("RedCloth") # for RDoc formatting
  s.add_development_dependency("rake")
  s.add_development_dependency("rspec", ">= 2.9.0")
  s.add_development_dependency("mocha", "0.10.5")
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.textile"
  ]
  s.require_paths = ["lib"]

end
