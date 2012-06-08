# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|

  s.name = %q{orientdb4r}
  s.version = '0.1.1'

  s.required_rubygems_version = Gem::Requirement.new('> 1.3.1') if s.respond_to? :required_rubygems_version=
  s.authors = ['Vaclav Sykora']
  s.date = %q{2012-06-08 08:21:02 +0200}
  s.description = %q{Orientdb4r provides a simple interface on top of OrientDB's RESTful HTTP API.}
  s.email = %q{vaclav.sykora@gmail.com}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.homepage = %q{http://github.com/veny/orientdb4r}
  s.rdoc_options = ['--charset=UTF-8']
  s.require_paths = ['lib']
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Ruby binding for Orient DB.}

  s.add_dependency(%q<rest-client>, ["~> 1.6.7"])
#  s.add_development_dependency(%q<json>, ["~> 1.5.1"])

end
