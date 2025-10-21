# -*- encoding: utf-8 -*-
# stub: image_size 3.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "image_size".freeze
  s.version = "3.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/toy/image_size/issues", "changelog_uri" => "https://github.com/toy/image_size/blob/master/CHANGELOG.markdown", "documentation_uri" => "https://www.rubydoc.info/gems/image_size/3.4.0", "source_code_uri" => "https://github.com/toy/image_size" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Keisuke Minami".freeze, "Ivan Kuchin".freeze]
  s.date = "2024-01-16"
  s.description = "Measure following file dimensions: apng, avif, bmp, cur, emf, gif, heic, heif, ico, j2c, jp2, jpeg, jpx, mng, pam, pbm, pcx, pgm, png, ppm, psd, svg, swf, tiff, webp, xbm, xpm".freeze
  s.homepage = "https://github.com/toy/image_size".freeze
  s.licenses = ["Ruby".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Measure image size/dimensions using pure Ruby".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.22"])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, ["~> 2.0"])
end
