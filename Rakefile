require 'bundler/setup'
require 'yaml'
require 'pathname'
require 'logger'
require 'fileutils'
require 'uglifier'
require 'sprockets'


include Rake::DSL

CONFIG      = YAML::load(File.open('./_config.yml'))
ROOT        = Pathname(File.dirname(__FILE__))
LOGGER      = Logger.new(STDOUT)
BUNDLES     = %w( all.css all.js )
BUILD_DIR   = ROOT.join(CONFIG['destination'], 'assets')
SOURCE_DIR  = ROOT.join(CONFIG['source'], 'assets')


"Compiles website"
task :compile do

  sh "jekyll"

  # compiling SCSS and CoffeeScript files

  sprockets = Sprockets::Environment.new(ROOT) do |env|
    env.logger = LOGGER
  end
  
  sprockets.append_path(SOURCE_DIR.join('javascripts').to_s)
  sprockets.append_path(SOURCE_DIR.join('stylesheets').to_s)

  BUNDLES.each do |bundle|
    assets = sprockets.find_asset(bundle)
    next unless assets

    prefix, basename = assets.pathname.to_s.split('/')[-2..-1]
    FileUtils.mkpath BUILD_DIR.join(prefix)

    assets.write_to(BUILD_DIR.join(prefix, basename))
    assets.to_a.each do |asset|
      # strip filename.css.foo.bar.css multiple extensions
      realname = asset.pathname.basename.to_s.split(".")[0..1].join(".")
      if realname =~ /^all.(css|js)$/
        asset.write_to(BUILD_DIR.join(prefix, realname))
      end
    end
  end

  # compressing all.js

  all_js = File.join BUILD_DIR, 'javascripts', 'all.js'
  min_js = File.join BUILD_DIR, 'javascripts', 'all.min.js'

  if File.exists? all_js
    minified = Uglifier.compile(File.read(all_js), :copyright => false)
    File.open(min_js, 'w') do |fh|
      fh.write minified
    end  
  end
end

desc "Deploys assets to GAE"
task :gae do
  build_assets

  rm_rf "/tmp/gaecdn"
  mkdir "/tmp/gaecdn"
  sh "cp -rf ./#{CONFIG['destination']}/assets /tmp/gaecdn/"
  sh "cp -rf ./lib/gae/* /tmp/gaecdn/"

  Dir.chdir("/tmp/gaecdn") do
    sh "appcfg.py update ."
  end
end

