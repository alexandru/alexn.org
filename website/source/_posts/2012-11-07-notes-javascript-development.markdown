---
layout: post
title: "Notes On Javascript Client-side Development"
tags:
  - Javascript
  - Functional
  - Browser
  - Web
---

{% img right /assets/photos/javascript_logo.jpg %}

Client-side Javascript development can be quite overwhelming, even for
senior developers. I'm describing here what I did in a recent piece of
client-side functionality to keep my sanity. This interface I'm
talking about is served on mobile-phones, so it must be pretty
bloat-free, adding salt over injury.

## Dealing with modules, packaging and minifying

This is probably my biggest gripe with Javascript, that you can't
simply `require("some.namespace")` without extra glue and tricks. This
is a limitation of the browser, as such operations would have to be
executed asynchronously, requiring tedious callbacks and because of
bandwidth constraints you may want to serve everything in a single
optimized and gzipped JS.

**[Brunch.io](http://brunch.io/)** is an awesome tool that helps you
do that. You split your project in multiple files, then Brunch can do
the assembling for you. To have modules in your project (splitting it
in several files), Brunch works with the
[CommonJS modules](http://wiki.commonjs.org/wiki/Modules/1.1)
interface. All that means is that your Javascript files will end-up
looking like this:

{% highlight javascript %}
// for importing another module
utils = require("path/to/utils")

function generateRandomString() {
    var userAgent = navigator.userAgent	
	var rnd = Math.random() * 100000000
    return utils.md5(userAgent + rnd);
}

// exporting function for consumption from other modules
modules.export = {
    generateRandomString: generateRandomString
}
{% endhighlight %}

Building changes and seeing them in your browser works really fast, as
Brunch can watch for changes in real-time and also exposes a built-in
server. So Brunch can take care of packaging for all your modules in a
single JS file, also minimizing for production if you want. The
workflow is pretty sweat, the configuration simple.

## Dealing with Javascript's Syntax Quirks

Javascript is a capable language exposed by an awful syntax and
plagued by incompatibilities - did you know that placing extra commas
or other punctuation will cause syntax errors in older browsers? So
it's not just about API incompatibilities, the syntax itself can lead
to surprises.

Brunch can be configured to check your code with
[JSHint](http://www.jshint.com/), which is a Linter that can check for
syntax errors and you can use it to force upon yourself and your team
certain best practices. It has a lot of
[configuration options](http://www.jshint.com/docs/) and for instance
it can trigger errors on uninitialized variables and other
tremendously useful stuff.

I've used [CoffeeScript](http://coffeescript.org/) as Brunch can work
with any language, with the proper plugin. I preferred CoffeeScript
because I develop in a more functional style and CoffeeScript has a
lighter syntax for anonymous functions, plus some other fixes to
Javascript, like "class" or the fat-arrow that binds the defined
function to the current `this` (tremendously useful). I coupled
CoffeeScript with [CoffeeLint](http://www.coffeelint.org/) and for
instance I disabled the implicit braces when declaring object
literals, as I hate that syntax and don't want to get sucked into
it. What I really wanted however was
[TypeScript](http://www.typescriptlang.org/), which is like
Javascript, but with nice add-ons. Unfortunately it's too immature and
so
[it isn't included by Brunch's authors yet](https://twitter.com/brunch/status/253571565923467264),
but it probably will be at some point. 

## Dealing with Async Events

Many people use [Backbone.js](http://backbonejs.org/) or things based
on it. What Backbone gives you, besides a structure for your app with
controllers and models, it also gives you a foundation for using the
[Observer pattern](http://en.wikipedia.org/wiki/Observer_pattern). So
your app initiates events that produce data and in response to user
actions or new data, you have to update stuff.

However my use-case was simple (the interface can be described by a
state-machine, without many things going on as far as the UI is
concerned). And *I absolutely hate* this consumer/producer model with
listeners, because I can't really wrap my head around it even for the
simplest of examples, as this model was really designed for usage
inside an IDE, where you can right-click on components and see all the
registered listeners for certain events.

**[The Q library](https://github.com/kriskowal/q)** - is one library
I'm using for dealing with *future* responses (a promise for a
response that may be available at a later time) and for avoiding the
[Pyramid of Doom](http://calculist.org/blog/2011/12/14/why-coroutines-wont-work-on-the-web/).

You see, many people choose something like Backbone because it makes
asynchronicity easier to deal with. I chose against it by building
small functions that compose, binding them together with Q. Works
great for small projects, even if the asynchronous calls are difficult
to compose, because working with promises makes that easy - note that
[jQuery's implementation is broken](https://gist.github.com/3889970),
so don't use it, just wrap jQuery's ajax calls in a Q promise.

Also, the great thing about preferring small functions with
referential transparency that compose is that testing becomes so much
easier. Brunch can also run your tests and you can use something like
[Chai](http://chaijs.com/) or other helpers for testing nirvana.

This doesn't mean that Backbone and data flows with something like Q
can't be used together. I can certainly see myself working with
Backbone for larger projects.

## Going Mobile

Other libraries I'm using are:

* [Underscore.js](http://underscorejs.org/), which provides much
  needed API additions, some of which are available in latest versions
  of JS, but not on older browsers. You definitely need this if you
  like to program in a more functional style  
* [Zepto](http://zeptojs.com/) instead of jQuery, because this
  interface is served on mobile phones and jQuery is pretty
  bloated. I'll also probably switch to
  [jqMobi](http://www.jqmobi.com/) because it's even lighter.

In regards to jQuery alternatives, well jQuery adds like 33KB of
gzipped Javascript to my download. This may not be an issue in a
browser that has jQuery already cached, but in a fresh
[WebView](http://developer.android.com/reference/android/webkit/WebView.html)
it's really big for normal 3G connections. My final JS file that gets
downloaded only has 20KB of gzipped JS, in total, including the
libraries I mentioned and it won't grow over 30KB. In combination with
a CDN like [CloudFront](http://aws.amazon.com/cloudfront/) that's
still reasonable.

The ideal would be to use something like the
[Google Closure](https://developers.google.com/closure/) compiler,
which can do tree-shaking, getting rid of pieces of code you don't
need. However, the code has to follow the Closure conventions,
otherwise it will behave no better than a normal minifier and
libraries like jQuery don't follow them. That's why I have high hopes
for [TypeScript](http://www.typescriptlang.org/), because it has a
built-in dependency system and you can annotate with types even
outside libraries, so a tree-shaker could work for popular libraries
if there's enough interest, even if the library in question does not
follow any conventions. I also thought about using
[ClojureScript](https://github.com/clojure/clojurescript), which emits
Closure-compatible Javascript, but I'm not familiar enough with the
language, so maybe some other day :-)

## As a conclusion

Keep things simple and work with tools provided by the Node.js
community, because that's where the real action is.
