# -*- encoding: utf-8 -*-
# stub: exifr 1.4.1 ruby lib

Gem::Specification.new do |s|
  s.name = "exifr".freeze
  s.version = "1.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://codeberg.org/rwv/exifr/issues", "changelog_uri" => "https://codeberg.org/rwv/exifr/raw/branch/master/CHANGELOG", "documentation_uri" => "https://www.rubydoc.info/gems/exifr", "homepage_uri" => "https://codeberg.org/rwv/exifr" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["R.W. van 't Veer".freeze]
  s.date = "2025-01-10"
  s.description = "EXIF Reader is a module to read EXIF from JPEG and TIFF images.".freeze
  s.email = "exifr@remworks.net".freeze
  s.executables = ["exifr".freeze]
  s.files = ["bin/exifr".freeze]
  s.homepage = "http://codeberg.org/rwv/exifr/".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Read EXIF from JPEG and TIFF images".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<test-unit>.freeze, ["= 3.1.5"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12"])
end
