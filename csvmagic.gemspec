# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "csvmagic/version"

Gem::Specification.new do |s|
  s.name        = "csvmagic"
  s.version     = CSVMagic::VERSION::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["James Sadler ( @freshtonic )"]
  s.email       = ["freshtonic@gmail.com"]
  s.homepage    = "http://github.com/freshtonic/csvmagic"
  s.summary     = CSVMagic::VERSION::SUMMARY
  s.description = "simple CSV manipulation from the command line"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  #s.add_development_dependency("cucumber",">=0.3")
  #s.add_development_dependency("fakefs",">=0.2.1")
  #s.add_development_dependency("syntax",">=1.0")
  #s.add_development_dependency("diff-lcs",">=1.1.2")
end

