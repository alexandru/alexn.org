# -*- encoding: utf-8 -*-
# stub: progress 3.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "progress".freeze
  s.version = "3.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/toy/progress/issues", "changelog_uri" => "https://github.com/toy/progress/blob/master/CHANGELOG.markdown", "documentation_uri" => "https://www.rubydoc.info/gems/progress/3.6.0", "source_code_uri" => "https://github.com/toy/progress" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ivan Kuchin".freeze]
  s.date = "2021-04-02"
  s.homepage = "https://github.com/toy/progress".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Show progress of long running tasks".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.0"])
end
