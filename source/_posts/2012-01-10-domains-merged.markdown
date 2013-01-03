---
layout: post
title: "Just Merged 2 Domains: Rationale, Setup"
archive: true
tags:
  - Publishing
  - SEO
  - Server
  - Heroku
---

I migrated *alexn.org* to a new domain name: *bionicspirit.com*.

*bionicspirit.com* was supposed to be a blog about Android-related
development, however I cannot focus on two blogs, one being a big
enough chore already. I also prefer *bionicspirit.com* because:

* it can be pronounced even over the phone, in English or in my native
  language,
* it is easier to remember, even if it is longer,
* it is a dot-com.

## 301 Permanent Redirect

I had to do a 301 Permanent Redirect for all requests, from
*alexn.org* to *bionicspirit.com*, without changing the path. This
keeps all links valid, keeps users happy and also keeps the Google
Juice flowing. Unfortunately my Google ranking did take a plunge into
obscurity, but hopefully it will recover.

**UPDATE:** oops, apparently Google Webmasters has the option to send
a request for *Change of Address*. Also, you don't have to completely
take your old domain off the net with the 301 Redirect - at first you
can add a *rel="canonical"* to your web pages, in your document's
head, like this:

```html
<link rel="canonical" href="http://www.newdomain.com/path/to/document">
```

More details about *rel="canonical"* you can find by viewing this
video by Matt Cutts: [About
rel="canonical"](http://support.google.com/webmasters/bin/answer.py?hl=en&answer=139394).

Unfortunately for me, the damage is done already. Well, I don't care
that much, it's just I was pretty fond to see my article on
[Cross-Domain, Cross-Browser Ajax Requests](http://bionicspirit.com/blog/2011/03/24/cross-domain-requests.html)
being the first result on Google and I hope that I'll get that ranking
back somehow.

## Configuring a Free Server for Handling HTTP 301 Redirects

In case you don't have a smart DNS service, here's how to do it
cheaply, using Heroku (again):

```bash
# new directory
mkdir mydomain
# change to it
cd mydomain

# initialize a git repository
git init .
```

Then create a file called "*Gemfile*", for specifying dependencies:

```ruby
source 'http://rubygems.org'

gem 'rack'

group :development do
  # command line tools
  gem 'heroku'
end
```

Install these prerequisites (on the command-line again):

```bash
# in case you don't already have Bundler installed:
gem install bundler

# and then ...
bundle install 
```

Create a Rack configuration file that handles your logic, called
"*config.ru*":

```ruby
# our Rack middleware

class RedirectBetweenDomains
  def call(env)
    request = Rack::Request.new(env)
    
    # replacement logic here:
    new_url = request.url.sub(/(https?:\/\/)[^\/]+/, '\1bionicspirit.com')
    [301, {"Location" => new_url}, []]
  end
end

run RedirectBetweenDomains.new
```

Now deploy on Heroku (from the command line):

```bash
# committing
git add .
git commit -m 'initial commit - rack config'

# creating heroku app
heroku create

# renaming to something nicer
heroku rename yourappid

# deploying on heroku
git push heroku master
```

When it finishes, you can test the setup on
*http://yourappid.heroku.com* (where *rabbit* is your application's
name). Also checkout their article on
[adding custom domains](http://devcenter.heroku.com/articles/custom-domains).

In case you're wondering, this is the Heroku instance I've got
configured: [alexn.heroku.com](http://alexn.heroku.com).
