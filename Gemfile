source 'http://rubygems.org'

gem "jekyll", "~> 4.1.1"
gem "support-for"
gem 'nokogiri'
gem 'classifier-reborn'
gem 'rb-gsl'
gem "mini_magick"
gem "image_optim"

group :jekyll_plugins do
  gem "jekyll-paginate-v2"
  gem 'jekyll-optional-front-matter'
  gem 'jekyll-titles-from-headings'
  gem 'jekyll-relative-links'
  gem 'jekyll-gist'
  gem 'jekyll-sitemap'
  gem "jekyll-last-modified-at"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# and associated library.
install_if -> { RUBY_PLATFORM =~ %r!mingw|mswin|java! } do
  gem "tzinfo", "~> 1.2"
  gem "tzinfo-data"
end

# Performance-booster for watching directories on Windows
gem "wdm", "~> 0.1.0", :install_if => Gem.win_platform?
