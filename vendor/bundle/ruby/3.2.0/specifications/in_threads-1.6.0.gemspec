# -*- encoding: utf-8 -*-
# stub: in_threads 1.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "in_threads".freeze
  s.version = "1.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/toy/in_threads/issues", "changelog_uri" => "https://github.com/toy/in_threads/blob/master/CHANGELOG.markdown", "documentation_uri" => "https://www.rubydoc.info/gems/in_threads/1.6.0", "source_code_uri" => "https://github.com/toy/in_threads" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ivan Kuchin".freeze]
  s.date = "2022-01-17"
  s.homepage = "https://github.com/toy/in_threads".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Run all possible enumerable methods in concurrent/parallel threads".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rspec-retry>.freeze, ["~> 0.3"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.22", "!= 1.22.2"])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, ["~> 2.0"])
end
