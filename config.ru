# Rack configuration file for serving a Jekyll-generated static
# website from Heroku, with some nice additions:
#
# * knows how to do redirects, with settings taken from ./rack-config.yaml
# * sets the cache expiry for HTML files differently from other static
#   assets, with settings taken from ./rack-config.yaml

require 'yaml'
require 'mime/types'
require "dalli"
require "rack-cache"

# main configuration file, also used by Jekyll
CONFIG = YAML::load_file(File.join(File.dirname(__FILE__), 'rack-config.yaml'))

# points to our generated website directory
PUBLIC = File.expand_path(File.join(File.dirname(__FILE__), "build"))

# For cutting down on the boilerplate

class BaseMiddleware
  def initialize(app)
    @app = app
  end

  def each(&block)
  end
end


# Rack middleware for correcting paths:
#  
# 1. redirects from the www. version to the naked domain version
#
# 2. converts directory/paths/ to directory/paths/index.html (most
#    importantly / to /index.html)

class PathCorrections < BaseMiddleware
  def call(env)
    env['PATH_INFO'] += 'index.html' if env['PATH_INFO'].end_with? '/'
    request = Rack::Request.new(env)

    if request.host.start_with?("www.")
      [301, {"Location" => request.url.sub("//www.", "//")}, self]
    else
      @app.call(env)
    end    
  end
end


# Middleware that enables configurable redirects. The configuration is
# done in the standard Jekyll rack-config.yaml file.
#
# Sample configuration in rack-config.yaml:
#
#   redirects:
#     - from: /docs/some-document.html
#       to: /archive/some-document.html
#       type: 301
#
# The sample above will do a permanent redirect from ((*/docs/dialer.html*))
# to ((*/archive/some-document.html*))

class Redirects < BaseMiddleware
  def call(env)
    request = Rack::Request.new(env)

    path = request.path_info
    ext  = File.extname(path)
    path += '/' if ext == '' and ! path.end_with?('/')

    if redirect = CONFIG['redirects'].find{|x| path == x['from']}
      new_location = redirect['to']
      new_location = request.base_url + new_location \
        unless new_location.start_with?("http")
      [redirect['type'] || 302, {'Location' => new_location}, self]
    else
      @app.call(env)
    end
  end
end


# The 404 Not Found message should be a simple one in case the
# mimetype of a file is not HTML (like the message returned by
# Rack::File). However, in case of HTML files, then we should display
# a custom 404 message

class Fancy404NotFound < BaseMiddleware
  def call(env)
    status, headers, response = @app.call(env)
    if status == 404 
      ext = File.extname(env['PATH_INFO'])
      if ext =~ /html?$/ or ext == '' or !ext
        headers = {'Content-Type' => 'text/html'}
        response = File.open(File.join PUBLIC, 'pages', '404.html')
      end
    end

    [status, headers, response]
  end
end


# Mimicking Rack::File
#
# I couldn't work with Rack::File directly, because for some reason
# Heroku prevents me from overriding the Cache-Control header, setting
# it to 12 hours. But 12 hours is not suitable for HTML content that
# may receive fixes and other assets should have an expiry in the far 
# future, with 12 hours not being enough. 

class Application < BaseMiddleware
  class Http404 < Exception; end

  def guess_mimetype(path)
    type = MIME::Types.of(path)[0] || nil
    type ? type.to_s : nil
  end

  def call(env)
    request = Rack::Request.new(env)
    path_info = request.path_info

    # a /ping request always hits the Ruby Rake server - useful in
    # case you want to setup a cron to check if the server is still
    # online or bring it back to life in case it sleeps

    if path_info == "/ping"
      return [200, {
          'Content-Type' => 'text/plain', 
          'Cache-Control' => 'no-cache'
      }, [DateTime.now.to_s]]
    end

    headers = {}
    if mimetype = guess_mimetype(path_info)
      headers['Content-Type'] = mimetype
      if mimetype == 'text/html'
        headers['Content-Language'] = 'en' 
        headers['Content-Type'] += "; charset=utf-8"
      end
    end

    begin
      # basic validation of the path provided
      raise Http404 if path_info.include? '..'
      abs_path = File.join(PUBLIC, path_info[1..-1])
      raise Http404 unless File.exists? abs_path

      # setting Cache-Control expiry headers
      type = path_info =~ /\.html?$/ ? 'html' : 'assets'
      headers['Cache-Control']  = "public, max-age="
      headers['Cache-Control'] += CONFIG['expires'][type].to_s

      status, response = 200, File.open(abs_path, 'r')
    rescue Http404
      status, response = 404, ["404 Not Found: #{path_info}"]
    end

    [status, headers, response]
  end
end


#
# the actual Rack configuration, using 
# the middleware defined above
#

# Defined in ENV on Heroku. To try locally, start memcached and uncomment:
# ENV["MEMCACHE_SERVERS"] = "localhost"
if memcache_servers = ENV["MEMCACHE_SERVERS"]
  use Rack::Cache,
    verbose: true,
    metastore:   "memcached://#{memcache_servers}",
    entitystore: "memcached://#{memcache_servers}"
end

use Redirects
use PathCorrections
use Fancy404NotFound

run Application.new(PUBLIC)