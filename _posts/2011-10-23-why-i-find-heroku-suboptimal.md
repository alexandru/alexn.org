---
title: "Why I Find Heroku Suboptimal"
tags:
  - Heroku
  - Server
  - Cloud
image: /assets/media/articles/heroku.png
last_modified_at: 2022-04-01 19:15:16 +03:00
generate_toc: true
description: >-
  Heroku is great. It basically allows you to avoid growing-up. The deployment itself couldn't be simpler, and when browsing their web interface for available add-ons, I feel like a child in a candy-store. But I've outgrown it.
---

<p class="intro withcap">
  I love freebies. I often find myself compelled to search for the best price / convenience ratio, and from this perspective you cannot really argue against something offered for free. And yet, here I am bitching and moaning about Heroku.
</p>

Heroku provides a free-quota that's a LOT more reasonable than all the shitty PHP hosting offerings out there. And when time comes to scale, it lets you scale nicely for a price.

<p class='info-bubble' markdown='1'>
  **UPDATE (Oct 21, 2013):** This article is outdated, sort of. Heroku's Cedar stack is awesome and cost-effective if you can design your app to be efficient in terms of throughput (which you can only achieve if you use a platform capable of high performance, like the JVM). I still think that when starting out, the next step after the free Heroku dyno, is to get your own VPS.
</p>

<p class="info-bubble">
  <strong>UPDATE (Dec 18, 2019):</strong> this is an old article, listing resources that may be obsolete and content that may not reflect my current views.
</p>

Normally you develop your app on your localhost (which is like this warm and cozy place for all developers, _no place like 127.0.0.1_ and all that), but then you want to deploy. You have to get out of your comfort zone and face the jungle and it's a true jungle out there, filled with shitty / underpowered and expensive hosting offerings. If going for a normal VPS, you'll have to configure your application server, your database server, your webserver that sits on top, maybe a reverse proxy cache, a memcached instance or two, a load balancer, a firewall, an email server and it goes on and on. And if going for a classic shared-hosting environment, then God help you.

There's a reason children with happy childhoods don't want to grow up - the world is an ugly and scary place.

## git push heroku master

Heroku is great. It basically allows you to avoid growing-up. The deployment itself couldn't be simpler, and when browsing their web interface for available add-ons, I feel like a child in a candy-store.

Basically you start with a free worker, to which you can add other "free" services, like a 5MB PostgreSql database and a 5MB Memcached instance, allowing you to prototype stuff. They even have plugins from third-parties that give you freebies, like a 250MB CouchDB, or a 240MB MongoDB. Then as you grow, you start adding more and more resources as needed. This has been labeled as _platform as a service_ and it's what the cool kids are talking about these days. Heck, there are people that are living within that free-quota without problems. One such example that I know of is [http://tzigla.com](http://tzigla.com) ... or it was last time I talked to the authors, both acquaintances of mine, and Cristi described how he ended-up doing lots of workarounds to get around limitations and he was really excited about how everything fell into place.

But as I was sitting there admiring their determination and skill, I started wondering why the hell haven't they rented a normal VPS?

I mean really, if you end up pulling all kinds of crap to get around limitations, wouldn't it be better to just pay up? And if you're short on cash or you're the kind of entrepreneur that likes to spend frugally, then wouldn't you be better just renting a normal VPS? I asked him just that of course, and his reply was basically:

_I hate to do sys-admin stuff, installing and upgrading packages and all that_

But it doesn't have to be that way. It's really not that hard. The reason for these feelings is the Ubuntu I have had installed on my primary laptop for 5 years already. Once you work with Ubuntu or your favorite Linux distribution, every day, configuring a web-server for starters is something like a half-an-hour chore. Or let's say 1 hour, and then it's done. And you don't have to worry about it again.

**And there are disadvantages to Heroku**, lots of them: that's because you lose control and end up on top of a platform that's designed as a common denominator to appeal to all needs in an equally substandard manner.

## Example 1: Nginx

Nginx is a freakishly fast web server that consumes really few resources. Its main appeal is in serving static files and you do have static files to serve. When you grow you may want to move those static files to a CDN, like CloudFront, which serves content from locations closer to the actual users, but for serving css/javascript and small images - a properly configured Nginx is all you need. And you can't really move any files served from your main domain to a CDN (like HTML content).

You can also be smart about semi-static pages in Rails - you can cache the output inside the _public/_ directory to be served by Nginx. And if you still want to hit your controller on every request, like when doing A/B Testing on a page, you can send an _X-Accel-Redirect_ header in your response to Nginx and let Nginx to the actual content streaming for you. You can also instruct Nginx to serve files from different locations, based on certain variables like the domain name, thus avoiding hitting the Rails application server on every request.

There's a lot you can do with Nginx if you're on a budget, and yet this is not possible within Heroku ... which even though it may use Nginx as an http reverse proxy, it certainly doesn't use it for serving static files. All files are thus served by hitting the Rails server, unless Varnish is involved.

## Example 2: Varnish

[Varnish](https://www.varnish-cache.org/) is described as being a _web application accelerator_ and the things it can do are truly mind-blowing.

Varnish sits in front of your application servers. It can do _load-balancing_ for you with extreme efficiency, although that's not its main purpose. Its main purpose is to cache content.

When caching content you have an extreme freedom to specify the Key for fetching cached items. You can use anything when instructing Varnish on what and how to cache, like cookies or the user's IP or any HTTP header. Do you want to also cache content for logged-in users, even though that content is slightly different from user to user? Not a problem. The configuration language is also extremely flexible, allowing you to tap in the request pipeline with any custom behavior you want. The performance of Varnish coupled with this extreme flexibility is what makes it great. It also has this uncanny ability to reload its configuration without restarting or dropping active connections.

Heroku has Varnish in its stable stack, called Bamboo. But you cannot configure it. The configuration is the same for everybody ... you basically set expiry headers on your response, Varnish caches it for you and the cache gets invalidated on every new deployment.

This is actually good and has given rise to the famous Heroku use-case: hosting mostly static websites on it. But Varnish can be much more than that, otherwise it kind of gets in your way, and surprise - Heroku is pulling Varnish out of the configuration, starting with the new Celadon Cedar stack. This is because Varnish gets in the way of their ambitious plans: to make heroku platform-agnostic, thus adding support for Node.js and long-pooling.

The now recommended alternative for serving cached static content is to use Rack::Cache in combination with their Memcached add-on. But this sucks because (1) it hits the Rails server on every request and in the free plan you only have a single process to serve those requests + (2) the free plan for Memcached is only 5MB.

## Example 3: asynchronous jobs

One common-sense approach to not having a sluggish web interface is to get slow code out of your HTTP process. Lots of libraries and plugins are available for all web frameworks, like _delayed_job_ for Rails or _Celery_ for Django. And you can just write your own half-baked jobs queue and shove it in your cron.

You cannot have asynchronous jobs using Heroku's free plan. You must get an extra dyno for that.

## Price comparison with Linode

The cheapest [Linode instance](http://www.linode.com/?r=c7376c22b7853329bfb629a54dc9a843be935c36) is **$20** per month, and for starters you can have ...

*   1 Nginx server
*   2 Passenger/Rails processes
*   1 worker for processing asynchronous jobs, it can even be a plain cron-job ; you do have complete flexibility in configuring cron-jobs
*   1 PostgreSQL database, configured for 256MB RAM usage, with 18 GB of storage. It's not much, but it isn't _shared_ either and does just fine, trust me ... btw, the [PostgreSQL magazine](http://pgmag.org/) (first issue) has an article about configuring/optimizing PostgreSQL's memory usage
*   1 Postfix email server, for bug reports + sending all the spam you want (Linode lets you configure reverse DNS lookup, so you can have a cheap email server that doesn't trigger spam alerts)
*   ability to serve for any domain you want, including wildcard subdomains
*   your own SSL certificate, for free depending on provider

The equivalent Heroku configuration would cost a minimum of **$114 per month**.

So lets say that you're growing and you want to add Ronin, Heroku's plan for a database of 1.7 GB _hot data set_ (whatever the fuck that means). That will cost you a whooping **$200 per month** extra, versus **$80** for a 2GB of RAM instance on Linode, or even better, $160 for a 4GB of RAM instance.

## Linode sucks too, but that's besides the point

You lose the ability to increase your dynos in response to traffic surges. On the other hand you'll be amazed at how much you can squeeze out of your rented hardware and if a properly configured setup fails to serve, then the problems you have probably can't be solved by just adding extra web servers.

Really, do some reading on why Reddit is down so often. Do some reading on why Amazon's EBS is completely unreliable for databases (btw, Heroku does use EBS and they've also had their share of downtime due to AWS experiencing problems).

Stop fearing the penguin and start configuring your own damn servers. As with everything that's actually worth it in life (like having children of your own), it's hard at first but the return of investment will be tenfold.
