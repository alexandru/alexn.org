require 'ostruct'
require 'yaml'
require "config/lib/helpers"

###
# Blog settings
###

Time.zone = "Europe/Bucharest"

activate :blog do |blog|
  # blog.prefix = "blog"
  blog.permalink = "blog/:year/:month/:day/:title.html"
  blog.sources = "blog/:year-:month-:day-:title.html"
  blog.taglink = "blog/tags/:tag.html"
  blog.layout = "post"
  # blog.summary_separator = /(READMORE)/
  # blog.summary_length = 250
  blog.year_link = "blog/:year.html"
  blog.month_link = "blog/:year/:month.html"
  blog.day_link = "blog/:year/:month/:day.html"
  # blog.default_extension = ".markdown"

  blog.tag_template = "tag.html"
  blog.calendar_template = "calendar.html"

  # blog.paginate = true
  # blog.per_page = 10
  # blog.page_link = "page/:num"
end

page "/atom.xml", :layout => false
page "/sitemap.xml", :layout => false
page "/utils/password.html", :layout => false

###
# Compass
###

# Susy grids in Compass
# First: gem install susy --pre
# require 'susy'

# Change Compass configuration
# compass_config do |config|
#   config.output_style = :compact
# end

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", :layout => false
#
# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy (fake) files
# page "/this-page-has-no-template.html", :proxy => "/template-file.html" do
#   @which_fake_page = "Rendering a fake page with a variable"
# end

###
# Helpers
###

# Automatic image dimensions on image_tag helper
activate :automatic_image_sizes

# Methods defined in the helpers block are available in templates
# helpers do
#   def some_helper
#     "Helping"
#   end
# end

set :css_dir, 'assets/css'

set :js_dir, 'assets/js'

set :images_dir, 'assets/img'

activate :syntax
set :markdown_engine, :kramdown
set :markdown, :syntax_highlighter => :rouge, :input => "GFM", :hard_wrap => false
# set :markdown, :fenced_code_blocks => true, :smartypants => true

# Build-specific configuration
configure :build do
  activate :minify_css
  activate :minify_javascript

  # activate :minify_html
  activate :asset_hash, :exts => [".css"]

  #activate :asset_host
  #set :asset_host do |asset|
  #  "//d2uy8r9dr9sdps.cloudfront.net".to_s
  #end

  # Enable cache buster
  # activate :cache_buster

  # Use relative URLs
  # activate :relative_assets
  activate :gzip
end

# Fixes error: Comparison of String with :current_path failed
begin
  warn_level = $VERBOSE
  $VERBOSE = nil
  Tilt::SYMBOL_ARRAY_SORTABLE = false
ensure
  $VERBOSE = warn_level
end
