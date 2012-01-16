# My Personal Blog (bionicspirit.com)

* generated with [Jekyll](https://github.com/mojombo/jekyll)

It was originally hosted on Heroku, relying on Google App Engine for
serving images and other static assets. See this article for details:

[Blogging for Hackers](http://bionicspirit.com/blog/2012/01/05/blogging-for-hackers.html)

Since then I've moved it to AWS's free tier, on a micro-instance, in
combination with CloudFront. But it is still ready for deployment on
Heroku/GAE (checkout config.ru) ... I'm just messing around, figuring
out which is the best/cheapest :)

As a Jekyll-generated website, it features:

* enhanced related articles functionality
* tag indexes that are also giving suggestions on other articles
  (related to that tag, but not tagged per se)
* Amazon book suggestions
* custom theme
* Delicious link recommendations (currently disabled)
* it's freakishly fast, easy to customize and cheap to host

## LICENSE

* you can do whatever you want with the code (_plugins, config.ru,
  Rakefile, other stuff)
* for the design and content, the license is Creative Commons BY-NC
  3.0 - if you want something less restrictive (i.e. commercial
  stuff), dropping me a line about it and depending on what you do, I
  may agree, as long as I'm getting attribution
