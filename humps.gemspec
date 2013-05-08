# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "humps/version"

Gem::Specification.new do |s|
  s.name        = "humps"
  s.version     = Humps::VERSION
  s.authors     = ["Cullen King"]
  s.email       = ["cullen@ridewithgps.com"]
  s.homepage    = "http://ridewithgps.com"
  s.summary     = %q{A library and sinatra server for working with elevation DEMs.}
  s.description = %q{Working with DEM files can be a PITA.  This library and server makes serving gridfloat based elevation DEM files easy.}

  #s.files         = `git ls-files`.split("\n")
  s.files         = Dir.glob('lib/**/*.rb')
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
