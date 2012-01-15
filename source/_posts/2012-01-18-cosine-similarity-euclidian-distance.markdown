---
layout: post
title: "Data Mining: Finding Similar Items"
has_ads: true
tags:
  - Algorithms
  - Programming  
  - Mining
  - Ruby
  - Jekyll
---

[{% img /assets/photos/xkcd435.png %}](http://xkcd.com/435/)

I'm showing you how to find related items based on a really simple
formula. If you pay attention, this technique all over the web (like
on Amazon) to personalize the user experience and increase conversion
rates. You can use it for:

* building a *Related Articles* section on your blog, which gives
  better conversions and a lower bounce-rate
* finding users with similar interests to a certain user, for the
  purposes of suggesting items the user hasn't thought about    
* finding similar / complementary / opposite items to suggest to
  customers of your shopping cart
 
We'll be using two very similar but different formulas:

* Cosine Similarity
* Euclidian Distance
  
## Understanding the Problem

To find similar items to a certain item, you've got to first define
what it means for 2 items to be similar and this depends on the
problem you're trying to solve:

* on a blog, you may want to suggest similar articles that share the
  same tags, or that have been viewed by the same people viewing the
  item you want to compare with
* Amazon has this section called "*users that bought this item also
  bought*", which is self-explanatory
* a service like IMDB, based on your ratings, could find users similar
  to you, users that liked or hated approximately the same movies you did,
  thus giving you suggestions on movies you'd like to watch
  
In each case you need a way to classify these items you're comparing,
whether it is tags, or items purchased, or movies reviewed. We'll be
using tags, as it is simpler, but the formula holds for more
complicated instances.

## Viewing the Solution

We'll be using my blog as sample. Let's take some tags:

{% highlight ruby %}
["API", "Algorithms", "Amazon", "Android", "Books", "Browser"]
{% endhighlight %}

That's 6 tags. Well, what if we considered these tags as dimensions in
a 6-dimensional
[Euclidian space](http://en.wikipedia.org/wiki/Euclidean_space)? Then
each item you want to sort or compare becomes a point in this space,
in which a coordinate (representing a tag) is either one (tagged) or
zero (not tagged).

So let's say we've got one article tagged with *API* and
*Browser*. Then its associated point will be:

{% highlight ruby %}
[ 1, 0, 0, 0, 0, 1 ]
{% endhighlight %}

Now these coordinates could represent something else. For instance
they could represent users. If say you've got a total of 6 users in
your system, 2 of them rating an item with 3 and 5 stars respectively,
you could have for the article in question this associated point
(do note the order is very important):

{% highlight ruby %}
[ 0, 3, 0, 0, 5, 0 ]
{% endhighlight %}

So now you can go ahead and calculate distances between these
points. For instance you could calculate the angle between the
associated vectors, or the actual euclidean distance between the 2
points. For a 2-dimensional Euclidean space, here's how it would look
like:

{% img center /assets/graphics/similarity-graphic.png %}

## Euclidean Distance

The mathematical formula for the Euclidean distance is really
simple. Considering 2 points, A and B, with their associated
coordinates, the distance is defined as:

{% img center /assets/graphics/euclidian-distance.gif %}

The lower the distance between 2 points, then the higher the
similarity. Here's some Ruby code:

{% highlight ruby %}
# Returns the Euclidean distance between 2 points
#
# Params:
#  - a, b: list of coordinates (float or integer)
#
def euclidean_distance(a, b)
  Math.sqrt(a.zip(b).map{|a,b| (a - b) ** 2}.inject(:+))
end

# Returns the associated point in the our space 
# of a list of tags.
#
# Params:
#  - tags_set: list of tags
#  - tags_space: _ordered_ list of tags
def tags_to_point(tags_set, tags_space)
  tags_space.map{|c| tags_set.member?(c) ? 1 : 0}
end

# Returns other_items sorted by similarity to this_item 
# (most relevant are first in the returned list)
#
# Params:
#  - items: list of hashes that have [:tags]
#  - by_these_tags: list of tags to compare with
def sort_by_similarity(items, by_these_tags)
  tags_space = by_these_tags + items.map{|x| x[:tags]}  
  tags_space.flatten!.sort!.uniq!

  this_point = tags_to_point(by_these_tags, tags_space)
  other_points = items.map{|i| 
    [i, tags_to_point(i[:tags], tags_space)]
  }

  similarities = other_points.map{|item, that_point|
    [item, euclidean_distance(this_point, that_point)]
  }
  
  sorted = similarities.sort {|a,b| a[1] <=> b[1]}
  return sorted.map{|point,s| point}
end
{% endhighlight %}

And here is the test you could do, and btw you can copy the above and
the bellow script and run it directly:

{% highlight ruby %}
# SAMPLE DATA

all_articles = [
  {
   :article => "Data Mining: Finding Similar Items", 
   :tags => ["Algorithms", "Programming", "Mining", 
     "Python", "Ruby"]
  }, 
  {
   :article => "Blogging Platform for Hackers",  
   :tags => ["Publishing", "Server", "Cloud", "Heroku", 
     "Jekyll", "GAE"]
  }, 
  {
   :article => "UX Tip: Don't Hurt Me On Sign-Up", 
   :tags => ["Web", "Design", "UX"]
  }, 
  {
   :article => "Crawling the Android Marketplace", 
   :tags => ["Python", "Android", "Mining", 
     "Web", "API"]
  }
]

# SORTING these articles by similarity with an article 
# tagged with Publishing + Web + API
#
#
# The list is returned in this order:
#
# 1. article: Crawling the Android Marketplace
#    similarity: 2.0
#
# 2. article: "UX Tip: Don't Hurt Me On Sign-Up"
#    similarity: 2.0
#
# 3. article: Blogging Platform for Hackers
#    similarity: 2.645751
#
# 4. article: "Data Mining: Finding Similar Items"
#    similarity: 2.828427
#

sorted = sort_by_similarity(
    all_articles, ['Publishing', 'Web', 'API'])

require 'yaml'
puts YAML.dump(sorted)
{% endhighlight %}

### The Flaw of Euclidean Distance

Can you see one flaw with it? I think you can - the first 2 articles
have the same Euclidean distance to ["Publishing", "Web", "API"], even
though the first article shares 2 tags with our chosen item, instead
of just 1 tag as the rest.

To visualize why, look at the points used in calculating the distance
for the first article:

{% highlight ruby %}
[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]
[1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1]
{% endhighlight %}

So 4 coordinates are different. Now look at the points used for the
second article:

{% highlight ruby %}
[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]
[0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1]
{% endhighlight %}

Again 4 coordinates are different. So here's **the flaw** for our
sample: similarity based on Euclidean distance does NOT care about the
coordinates (tags) that are the same. It only cares about coordinates
that *are different*. This method of measurement works great in cases
in which you have ratings involved, instead of just ones and zeros,
like we've used here for tags.

## Cosine Similarity

This method is very similar to the one above, but does tend to give
slightly different results. Here's the formula:

{% img center /assets/graphics/cosine-similarity.gif %}

If you look at the visual with the 2 axis and 2 points, we need the
cosine of the angle *theta* that's between the vectors associated with
our 2 points. And for our sample it does give better results.

The values will range between -1 and 1. -1 means that 2 items are
total opposites, 0 means that the 2 items are independent of each
other and 1 means that the 2 items are very similar.

Here's some Ruby code for you:

{% highlight ruby %}
def dot_product(a, b)
  a.zip(b).map{|a, b| a * b}.inject(:+)
end

def magnitude(point)
  Math.sqrt(point.map{|x| x ** 2}.inject(:+))
end

# Returns the cosine of the angle between the vectors 
#associated with 2 points
#
# Params:
#  - a, b: list of coordinates (float or integer)
#
def cosine_similarity(a, b)
  dot_product(a, b) / (magnitude(a) * magnitude(b))
end
{% endhighlight %}

Also, sorting the articles in the above sample gives me the following:

{% highlight yaml %}
- article: Crawling the Android Marketplace
  similarity: 0.5163977794943222

- article: "UX Tip: Don't Hurt Me On Sign-Up"
  similarity: 0.33333333333333337

- article: Blogging Platform for Hackers
  similarity: 0.23570226039551587

- article: "Data Mining: Finding Similar Items"
  similarity: 0.0
{% endhighlight %}

Right, so much better for this chosen sample.

## Go Forth and Give Kick-ass Suggestions

There is no one size fits all and the formula you're going to use
depends on your data and what you want out of it.

For instance the
[Manhattan Distance](http://en.wikipedia.org/wiki/Taxicab_geometry) is
more useful when you want to find users with the same likes or
dislikes, but that give ratings on different scales - for example on
IMDB, 2 users may like or dislike the same movies, but the scale of
one when rating may be from 1 to 5, while for the other it may be from
1 to 10.

Also do checkout the *related articles* sections on this blog. It is
how I've solved the problem of lonely tags. Checkout this tag index
page: [SEO](http://localhost:4000/tags/SEO/). 

Compare it with your average Wordpress tag index. Ain't this a lot
nicer? Yes, it's a Jekyll plugin. In case you want it for your own
Jekyll website, you can find the code in
[my repo](https://github.com/alexandru/bionicspirit.com/blob/master/source/_plugins/01-related-pages.rb)
(drop it in a directory called _plugins).