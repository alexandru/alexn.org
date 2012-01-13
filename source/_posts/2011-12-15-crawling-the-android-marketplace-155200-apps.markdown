---
title: "Crawling the Android Marketplace"
layout: post
categories: 
  - Tutorial
  - Programming
  - Python
  - Android
  - Web
  - API
---

I had a very specific need for fetching the details for some apps in
the marketplace, in an automated manner. And so I found
[the supermarket gem](https://github.com/jberkel/supermarket), a
wrapper for the
[Android Market API](http://code.google.com/p/android-market-api/)
Java implementation. However, it gives unpredictable results (it
wouldn't return the details of our in-house apps or of many other
examples I tried) and Google is placing hard-limits on the number of
requests you can make per minute. This is an internal API, probably
used by the marketplace client and the implementation mentioned above
was created through reverse-engineering.

This really pissed me off, this is Google, they should grok APIs. But
this info is already available from their website and so I went ahead
and crawled it.

The script <strike>and the data collected are</strike> is available. Read below.

<!-- more -->

## How To Do it By Yourself

{% img right /assets/photos/wolfspider150.gif %}

The actual script that I created can be found in the
[AndroidMarketCrawler](https://github.com/alexandru/AndroidMarketCrawler)
GitHub Repository, with the relevant files being:

* [crawler.py](https://github.com/alexandru/AndroidMarketCrawler/blob/master/crawler.py) - source code with lots of comments, it's really not complicated, you should go read it
* <strike>marketplace_database.json_lines.bz2 - compressed file
  containing the details of the crawled apps, one per each line; this
  is not a proper JSON file, you use it by reading it line by line,
  where each line represents a JSON object (personal preference, as
  otherwise the file is pretty big and you can run out of
  memory)</strike>

UPDATE: I decided to pull the crawled data out, deleting it. The
Android Marketplace explicitly bans crawling apparently.

{% highlight python %}
for app in AndroidMarketCrawler(concurrency=10):
    # app is at this point a dictionary with the details needed, like
    #  id, name, developer name, number of installs, etc...
    fh.write(json.dumps(app) + "\n")
{% endhighlight %}

I used the Python programming language, along with
[Eventlet](eventlet.net) for fetching URLs in parallel (async I/O with
epoll/libevent, providing you with coroutines support and green
threads) and [PyQuery](http://packages.python.org/pyquery/) for
selecting DOM elements using CSS3 selectors (instead of XPath or
BeautifulSoup). If you fancy Ruby instead, you could use slight
equivalents such as
[em-http-request](https://github.com/igrigorik/em-http-request) and
[Nokogiri](http://nokogiri.org/).

So you start fetching content from a root and add application links as
you encounter them in a queue. We are then using a (green) threadpool
to start fetching jobs for each of the links in the queue. So it's
recursive. The results are also pushed in another queue, ready to be
consumed by the client.

Be careful though, don't abuse this, as it will generate a ton of
traffic and your IP may end up being banned by Google. It also takes a
lot of time; with good bandwidth and a VPS located in California, it
still took me 5 hours for the script to finish. Don't abuse the
concurrency settings either, 10 is enough.

## 155,200 Apps Available From the US

You have to realize that this number is only approximate. Apps are
going strong in other countries, such as South Korea and Google does
Geo-IP filtering, which means some of the apps were unavailable to me,
depending on restrictions set by their developers.

The numbers published by
[Research2Guidance in October](http://www.readwriteweb.com/mobile/2011/10/android-market-hits-500000-suc.php)
tell the story of 500,000 apps published on the Marketplace. But this
gets weird, as I took the number of downloads from those 155,200 apps
and it *matches* the number of downloads
[published by Google this month](http://android-developers.blogspot.com/2011/12/10-billion-android-market-downloads-and.html). See
below.

### An Average of 13.63 Billion Downloads

So there have been between 5,514,202,281 and 21,545,335,515 downloads
for *free apps*, making the average 13,529,768,898 downloads.

More interesting however is that according to my data for paid apps,
the number of downloads is between 42,576,311 and 164,116,615. This
number seems rather low to me, making it clear that Android
distribution is freemium based.

*UPDATE: initially here there were some charts showing the popularity
of free/paid apps per category. I deleted them as I don't like the
flames these kind of charts generate!*

## Conclusion

I don't think I have one. Upon analyzing the data, it seems to me like
the development model of Android resembles that of the web - lots of
freemium apps, lots of crap. However, there are gems on the market
available and there are developers making a decent income from
publishing on Android's Marketplace. Competition is tough, but it is
(for now at least) an unregulated free market with tremendous
potential.
