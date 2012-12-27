require 'bundler/setup'
require 'erb'
require 'yaml'

include Rake::DSL
CONFIG = YAML::load(File.open('./_config.yml'))


task :compile do
  sh "jekyll"

  sh "mkdir -p build/conf"
  sh "cp lib/nginx-conf/* build/conf/"

  Dir.entries("build/conf/").find_all{|x| x =~ /\.erb$/}.each do |erb_file|
    erb_path = "build/conf/#{erb_file}"
    erb_destination = erb_path.gsub(/\.erb$/, "")
    content = File.read(erb_path)
    template = ERB.new content
    File.open(erb_destination, "w") do |fh|
      fh.write(template.result)
    end
    sh "rm #{erb_path}"
    puts "Processed #{erb_destination}"
  end
end

namespace :deploy do

  desc "Deploys assets to GAE"
  task :gae do
    Dir.entries('./lib/gae/').find_all{|x| x =~ /app\d+.ya?ml/}.each do |app|
      config = YAML::load(File.read "./lib/gae/#{app}")

      puts
      puts "Deploying CDN #{config['application']}.appspot.com ..."
      puts

      rm_rf "/tmp/gaecdn"
      mkdir "/tmp/gaecdn"
      sh "cp -rf ./#{CONFIG['destination']}/assets /tmp/gaecdn/"

      sh "cp -rf ./lib/gae/* /tmp/gaecdn/"
      sh "cp ./lib/gae/#{app} /tmp/gaecdn/app.yaml"    
      sh "rm /tmp/gaecdn/#{app}"

      Dir.chdir("/tmp/gaecdn") do
        sh "appcfg.py update ."
      end  
    end
  end

  desc "Deploy assets to CloudFront/S3"
  task :aws do
    # sets a 1 year expiry header this also means that resources can't
    # be updated without invalidating them first in CloudFront, which is
    # a PITA, so this is good for images, but not CSS
    sh 's3cmd sync ./build/html/assets/ s3://bionicspirit/assets/ --acl-public --add-header "Cache-Control: public, max-age=22896000"'
  end
end

task :default => [:compile]
