---
layout: post
title: "Merging Two Domains - alexn.org and bionicspirit.com"
categories:
  - tutorial
  - servers
  - heroku
  - publishing
---

I apologize if your feed reader went rogue and flagged all articles as
being unread. I migrated *alexn.org* to a new domain name:
*bionicspirit.com*.

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
Juice flowing.

In case you don't have a smart DNS service, here's how to do it
cheaply, using Heroku (again):

{% highlight bash %}
# new directory
mkdir mydomain
# change to it
cd mydomain

# initialize a git repository
git init .
{% endhighlight %}

Then create a file called "*Gemfile*", for specifying dependencies:

{% highlight ruby %}
source 'http://rubygems.org'

gem 'rack'

group :development do
  # command line tools
  gem 'heroku'
end
{% endhighlight %}

Install these prerequisites (on the command-line again):

{% highlight bash %}
# in case you don't already have Bundler installed:
gem install bundler

# and then ...
bundle install 
{% endhighlight %}

Create a Rack configuration file that handles your logic, called
"*config.ru*":

{% highlight ruby %}
# our Rack middleware

class RedirectBetweenDomains
  def call(env)
    request = Rack::Request.new(env)
    
    # replacement logic here:
    new_url = request.url.sub("alexn.org", "bionicspirit.com")

    [301, {"Location" => new_url}, []]
  end
end

run RedirectBetweenDomains.new
{% endhighlight %}

Now deploy on Heroku (from the command line):

{% highlight bash %}
# committing
git add .
git commit -m 'initial commit - rack config'

# creating heroku app
heroku create

# renaming to something nicer
heroku rename yourappid

# deploying on heroku
git push heroku master
{% endhighlight %}

When it finishes, you can test the setup on
*http://yourappid.heroku.com* (where *rabbit* is your application's
name). Also checkout their article on
[adding custom domains](http://devcenter.heroku.com/articles/custom-domains).


