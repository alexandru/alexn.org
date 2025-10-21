# -*- encoding: utf-8 -*-
# stub: fspath 3.1.2 ruby lib

Gem::Specification.new do |s|
  s.name = "fspath".freeze
  s.version = "3.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/toy/fspath/issues", "documentation_uri" => "https://www.rubydoc.info/gems/fspath/3.1.2", "source_code_uri" => "https://github.com/toy/fspath" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ivan Kuchin".freeze]
  s.date = "2019-07-14"
  s.homepage = "http://github.com/toy/fspath".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Better than Pathname".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.59"])
end
