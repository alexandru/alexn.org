---
layout: post
title: "Blogging Platform for Hackers"
has_ads: true
tags:
  - Publishing
  - Server
  - Cloud
  - Heroku
  - GAE
  - Ruby
  - Jekyll
---

{% img right /assets/photos/heroku.png %}

I'm showing you how to:

* host your own static website on Heroku's free plan;
* use Google's App Engine as a CDN, for better responsiveness;
* keep Heroku's free dyno alive, by using a GAE cron job;
* have a very responsive, scalable and secure blog, with ultimate;
  control and simplicity, for zero bucks per month;

You could just skip this article and browse the source code of my
blog:

* [github.com/alexandru/bionicspirit.com](https://github.com/alexandru/bionicspirit.com)

Forget about Wordpress or Blogger. Hacking your own stuff is much more
fun. Also, make sure to read
[Blogging Like a Hacker](http://tom.preston-werner.com/2008/11/17/blogging-like-a-hacker.html),
by Tom Preston-Werner, GitHub's cofounder and the author of Jekyll.

*UPDATE: article was changed three times to better express
rationale and in response to user feedback.*

## Jekyll and Heroku, Sitting in a Tree

I love [Jekyll](https://github.com/mojombo/jekyll), the static
website generator. It is pure awesomeness for me:

* all content is hosted in a Git repository, the best CMS ever
  invented
* my articles are written in Markdown, with Emacs, the most potent
  text editor ever created - think Textmate-snippets, macros, syntax
  highlighting, keyboard-driven navigation and spelling corrections
* static content scales like crazy, without any special gimmicks. A
  small VPS can serve thousands of requests per second without a
  sweat
* static content is also secure by default, no constant upgrades
  required, no SQL injections  
* I always make little tweaks to my design, I'm never satisfied, which
  is why it makes sense to make my own, but checkout
  [Octopress](http://octopress.org/) in case you want a reasonable
  default    
* I've lost an entire blog when my hosting account got blocked in the
  past. Never again, as my content is right now saved in 2 Git
  repositories and on my local machine  
* by working with my own domain, making my own shit, Google will never
  make me cry ;-)

Jekyll's first hosting option you should consider is
[GitHub Pages](http://pages.github.com/), however you will need *some*
dynamic behavior, like having configurable redirects. If you don't
then ignore this post and just read
[Jekyll's tutorial](https://github.com/mojombo/jekyll/wiki/usage), but
you can come back to this post when its limits start bothering you.

Heroku's free plan is awesome, in spite of what
[I said previously](/blog/2011/10/23/why-i-find-heroku-suboptimal.html).
It's great for prototyping and for quickly seeing your website
online. Instant gratification is awesome. Well, it does have some
problems and to tell you the truth, for hosting my blog I would have
rather used Google's [App Engine](http://code.google.com/appengine/),
if only they allowed me to have naked domains. I like my domains to be
naked.

One note in regards to the scalability of static content I mentioned
above. In Heroku the Bamboo stack features a Varnish frontend. If you
set proper expiry headers on your content, subsequent requests will
not hit the Ruby server.

## Hosting Static Content on Heroku

So this tutorial is about hosting a Jekyll website, which is why I'm
going to make some assumptions about your directory structure. However
you can modify these instructions for any static website, not just
Jekyll-generated stuff.

First, the setup:

{% highlight bash %}
# install the heroku command-line utility
gem install heroku

# change to your website directory
cd website/

# initialize a git repo, if you haven't done so
git init
# ... and commit everything to it
git add .
git commit -m 'initial commit'

# create the heroku app
heroku create
{% endhighlight %}

OK, now we need a Rake-powered application to serve our
content. We'll need a *./Gemfile* ...

{% highlight ruby %}
source 'http://rubygems.org'

gem 'rack'
gem 'mime-types'

group :development do
  gem 'jekyll'
  gem 'rdiscount'
  gem 'hpricot'  
end
{% endhighlight %}

Then install these gems with:

{% highlight bash %}
bundle install
{% endhighlight %}

You also need a Rake configuration file, *./config.ru*. What follows is the
configuration that I am using. You can go simpler, a lot simpler than
this actually, but I like flexibility and Heroku also does something
funny with files served through Rack::File, so I refrained from using
it ...

{% highlight ruby %}
# Rack configuration file for serving a Jekyll-generated static
# website from Heroku, with some nice additions:
#
# * knows how to do redirects, with settings taken from ./_config.yaml
# * sets the cache expiry for HTML files differently from other static
#   assets, with settings taken from ./_config.yaml

require 'yaml'
require 'mime/types'

# main configuration file, also used by Jekyll
CONFIG = YAML::load_file(File.join(File.dirname(__FILE__), '_config.yml'))

# points to our generated website directory
PUBLIC = File.expand_path(File.join(File.dirname(__FILE__), 
                          CONFIG['destination'] || '_site'))

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
# done in the standard Jekyll _config.yml file.
#
# Sample configuration in _config.yml:
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

use Redirects
use PathCorrections
use Fancy404NotFound

run Application.new(PUBLIC)
{% endhighlight %}

This Rack configuration uses settings defined in the standard Jekyll
*_config.yaml* file. Here are some settings needed for it to work as
intended:

{% highlight yaml %}
destination: ./_site

expires:
  html: 3600 # one hour
  assets: 1314000 # one year

redirects:
  - from: /rss/
    to: http://feeds.feedburner.com/bionicspirit
    type: 302
{% endhighlight %}

OK, so once done, test this configuration:

{% highlight bash %}
# generating the website
jekyll

# starting the server
rackup
{% endhighlight %}

Deployment is as easy as pie:

{% highlight bash %}
git push heroku master
{% endhighlight %}

One note: Heroku could be configured to automatically generate the
website for you. However you either have to use the Cedar stack, or
generate the pages on the fly. In case of the Cedar stack, you lose
Varnish. Just keep your generated files in Git, it's easier.

## Commenting with Disqus, Facebook or Roll Your Own

For commenting [Disqus](http://disqus.com) is a really good
service. In case you have a very popular website amongst normal
people, it may be even better to integrate Facebook's commenting
widget.

Well, I had some fun a while ago and created my own:
[TheBuzzEngine](https://github.com/alexandru/TheBuzzEngine).

Unfortunately it doesn't have all the features I want, but it does get
the job done and it isn't bloated. These days I'll probably get around
to adding some stuff to it, like threaded comments and email
subscriptions. This is what happens when working for fun on stuff -
once you're over a certain threshold, the return of investment is too
low to bother with extra development.

I recommend Disqus, although rolling your own is fun and keeps you in
control (which is the reason I'm using Jekyll in the first place).

## Using Google App Engine as Your CDN or Cron Manager

So when using Heroku's free plan, I feel a little uncomfortable
because relying on one dyno can get you in trouble. Having Varnish in
front is great, but Varnish is a cache manager. For instance, if you
happen to push a new version of your latest article to Heroku, then
the Varnish cache gets cleared and the Ruby server can potentially get
exposed to a lot of requests and one dyno on Heroku can only serve one
request at a time.

So why not push all our static assets, except HTML files, to a CDN?
It's best practice anyway as your website should be more
responsive. If you have an Amazon AWS account, then CloudFront + S3
are great.

However, I started with the goal of hosting this for zero bucks (it's
fun, so why not?). Therefore I'm going to teach you how to push your
files to Google's [App Engine](http://code.google.com/appengine/). I
don't really know how GAE works as a CDN for static files, but it
seems that it does have the
[properties of a CDN](http://blog.sallarp.com/google-app-engine-cdn/)
(i.e. serving content to users from servers closer to their location).

Another problem with Heroku's free plan is that the free dyno goes to
sleep, to save resources. While I advise you to just pay up for an
extra dyno, you can get around this restriction by just configuring
GAE to send a periodic *ping* to your website.

Here's my GAE configuration file, *app.yaml* which should sit in your
root (assuming *./assets* is the directory you want to serve from GAE):

{% highlight yaml %}
application: assets-bionicspirit
version: 1
runtime: python27
api_version: 1
threadsafe: true

handlers:

- url: /assets
  static_dir: assets
  expiration: "365d"

# next item is for our cron job, described below, but you can ignore
# it if you don't want a cron job ...

- url: /tasks/ping
  script: ping.app
{% endhighlight %}

As you can see, I'm setting the expiry of my static assets to a
whooping 1 year. 

I also have a real handler, at */tasks/ping* configured. This will be
our cron job that sends a ping to our Heroku app, every X
minutes. Here's the code for *ping.py* ...

{% highlight python %}
import webapp2
from google.appengine.api import urlfetch

class PingService(webapp2.RequestHandler):
  def get(self):
      self.response.headers['Content-Type'] = 'text/plain'

      url = "http://bionicspirit.com/ping"
      try:
          result = urlfetch.fetch(url, deadline=30)
          self.response.out.write('HTTP %d - %s' % 
              (result.status_code, (result.content or '').strip()))
      except:
          self.response.out.write('ERROR: no response')

app = webapp2.WSGIApplication([('/tasks/ping', PingService)], debug=False)
{% endhighlight %}

But we are not done. To configure */tasks/ping* to run every X
minutes, you also need a *cron.yaml* file ...

{% highlight yaml %}
cron:
- description: ping bionicspirit.com to wake it up
  url: /tasks/ping
  schedule: every 4 minutes
{% endhighlight %}

Assuming you already have the
[GAE SDK installed](http://code.google.com/appengine/docs/python/gettingstarted/devenvironment.html),
then run this command:

{% highlight bash %}
appcfg.py update .
{% endhighlight %}

To see it working on this blog, here are the requests:

* Heroku URL getting requested: [http://bionicspirit.com/ping](http://bionicspirit.com/ping)
* GAE Cron Job getting executed: [http://assets-bionicspirit.appspot.com/tasks/ping](http://assets-bionicspirit.appspot.com/tasks/ping)

## Extra Tip - CloudFlare

Luigi Montanez kindly pointed out in below's comments the availability
of [CloudFlare](https://www.cloudflare.com/).

CloudFlare is a proxy that sits between your website and your
users. It allegedly prevents DDOS attacks on your website, but it also
caches static content, which helps because apparently it also has the
properties of a CDN. 

I activated it to see how it works. The main reason is that GAE has a
1 GB bandwidth-out daily limit - and this article generated ~ 10,000
visits in only one day, which consumed ~ 700 MB of bandwidth on GAE
(for a couple of small images, I don't want to imagine what would
happen for an image-rich post). So that's not good and I placed
CloudFlare in front of GAE and my Heroku instance, which should save
some bandwidth for me.

I don't have a conclusion on CloudFlare. If it works as advertised,
then it is *awesome*. Although be careful about it as I've seen
reports on the Internet that it may in fact add latency to your
website, instead of decreasing it.

For my website however, everything seems to be fine. I am monitoring
my website with [Pingdom.com](http://pingdom.com), a service which
also reports the average responsiveness of the website, calculated by
doing requests from multiple locations. The homepage, which is not
cached by CloudFlare or served by GAE, has an average load time of
300ms, while cached static resources from GAE and proxied through
CloudFlare are doing much better.

So we'll see.

## Conclusion

The result is a really responsive, scalable and kick-ass blog, for
zero bucks spent on hosting. 

This very blog is hosted using the method described above. Well, I'll
probably return to my trustworthy VPS instance as I'm paying for it
anyway, but this was fun.

Enjoy ~
