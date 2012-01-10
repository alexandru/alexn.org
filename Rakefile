require 'bundler/setup'
require 'yaml'

include Rake::DSL
CONFIG = YAML::load(File.open('./_config.yml'))


desc "Deploys assets to GAE"
task :gae do
  rm_rf "/tmp/gaecdn"
  mkdir "/tmp/gaecdn"
  sh "cp -rf ./#{CONFIG['destination']}/assets /tmp/gaecdn/"
  sh "cp -rf ./lib/gae/* /tmp/gaecdn/"

  Dir.chdir("/tmp/gaecdn") do
    sh "appcfg.py update ."
  end
end

