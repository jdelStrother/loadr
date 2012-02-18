# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "loadr/version"

Gem::Specification.new do |s|
  s.name        = "loadr"
  s.version     = Loadr::VERSION
  s.authors     = ["Jonathan del Strother"]
  s.email       = ["jon.delStrother@audioboo.fm"]
  s.homepage    = ""
  s.summary     = %q{Profile load times of ruby code}
  s.description = %q{Loadr measures time taken to 'require' each file, to give an indication where your startup time is being spent}

  s.rubyforge_project = "loadr"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
