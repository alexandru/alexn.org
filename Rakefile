require 'bundler/setup'
require 'yaml'

include Rake::DSL
CONFIG = YAML::load(File.open('./_config.yml'))

task :compile do
  sh "jekyll"

  sh "mkdir -p build/conf"
  sh "cp lib/nginx-conf/* build/conf/"
end

task :default => [:compile]
