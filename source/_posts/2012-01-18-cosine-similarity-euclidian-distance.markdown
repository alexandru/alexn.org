---
layout: post
title: "Data Mining: Giving Kick-ass Product&nbsp;Recommendations"
has_ads: true
tags:
  - Algorithms
  - Programming  
  - Mining
  - Ruby
---

{% img right /assets/graphics/similarity-graphic-small.png %}

I'm showing you how to find related items based on a really simple
formula. If you pay attention, this technique is used all over the web
(like on Amazon) to personalize the user experience and increase
conversion rates. 

To get one question out of the way: there are already many available
libraries that do this, but as you'll see there are multiple ways of
skinning the cat and you won't be able to pick the right one without
understand the process, at least intuitively.
  
## Defining the Problem

{% img right /assets/photos/amazon.png Amazon gives kick-ass suggestions to their customers %}

To find similar items to a certain item, you've got to first define
what it means for 2 items to be similar and this depends on the
problem you're trying to solve:

* on a blog, you may want to suggest similar articles that share the
  same tags, or that have been viewed by the same people viewing the
  item you want to compare with
* Amazon has this section called "*customers that bought this item also
  bought*", which is self-explanatory
* a service like IMDB, based on your ratings, could find users similar
  to you, users that liked or hated approximately the same movies you did,
  thus giving you suggestions on movies you'd like to watch in the future
  
In each case you need a way to classify these items you're comparing,
whether it is tags, or items purchased, or movies reviewed. We'll be
using tags, as it is simpler, but the formula holds for more
complicated instances.

## Redefining the Problem in Terms of Geometry

We'll be using my blog as sample. Let's take some tags:

{% highlight ruby %}
["API", "Algorithms", "Amazon", "Android", "Books", "Browser"]
{% endhighlight %}

That's 6 tags. Well, what if we considered these tags as dimensions in
a 6-dimensional
[Euclidean space](http://en.wikipedia.org/wiki/Euclidean_space)? Then
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

{% img center /assets/graphics/euclidean-distance.png %}

The lower the distance between 2 points, then the higher the
similarity. Here's some Ruby code:

{% highlight ruby %}
# Returns the Euclidean distance between 2 points
#
# Params:
#  - a, b: list of coordinates (float or integer)
#
def euclidean_distance(a, b)
  sq = a.zip(b).map{|a,b| (a - b) ** 2}
  Math.sqrt(sq.inject(0) {|s,c| s + c})
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

### The Problem (or Strength) of Euclidean Distance

Can you see one flaw with it for our chosen data-set and intention? I
think you can - the first 2 articles have the same Euclidean distance
to ["Publishing", "Web", "API"], even though the first article shares
2 tags with our chosen item, instead of just 1 tag as the rest.

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

Again, 4 coordinates are different.So here's the deal with Euclidean
distance: it measures *dissimilarity*, instead of similarity. The
coordinates that are the same are less important than the coordinates
that are different. For my purpose here, this is not good - because
articles with more tags (or less) tags than the average are going to
be disadvantaged. 

## Cosine Similarity

This method is very similar to the one above, but does tend to give
slightly different results, because this one actually measures
similarity instead of dissimilarity. Here's the formula:

{% img center /assets/graphics/cosine-similarity.png %}

If you look at the visual with the 2 axis and 2 points, we need the
cosine of the angle *theta* that's between the vectors associated with
our 2 points. And for our sample it does give better results.

The values will range between -1 and 1. -1 means that 2 items are
total opposites, 0 means that the 2 items are independent of each
other and 1 means that the 2 items are very similar (btw, because we
are only doing zeros and ones for coordinates here, this score will
never get negative for our sample).

Here's the Ruby code (leaving out the wiring to our sample data, do
that as an exercise):

{% highlight ruby %}
def dot_product(a, b)
  products = a.zip(b).map{|a, b| a * b}
  products.inject(0) {|s,p| s + p}
end

def magnitude(point)
  squares = point.map{|x| x ** 2}
  Math.sqrt(squares.inject(0) {|s, c| s + c})
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

Right, so much better for this chosen sample and usage. Ain't this
fun?

## Pearson Correlation Coefficient

The
[Pearson Correlation Coefficient](http://en.wikipedia.org/wiki/Pearson_product-moment_correlation_coefficient)
for finding the similarity of 2 items is slightly more sophisticated
and doesn't really apply to my chosen data-set. This coefficient
measures how well two samples are linearly related.

For example, on IMDB we may have 2 users. One of them, lets call him
John, has given the following ratings to 5 movies:
[1, 2, 3, 4, 5]. The other one, Mary, has given the following ratings
to the same 5 movies: [4, 5, 6, 7, 8]. The 2 users are very similar,
as there is a perfect linear correlation between them, since Mary just
gives the same rankings as John times 4. The formula itself or the
theory is not very intuitive though. But it is simple to calculate:

{% img center /assets/graphics/pearson.png %}

Here's the code:

{% highlight ruby %}
def pearson_score(a, b)
  n = a.length
  return 0 unless n > 0

  # summing the preferences
  sum1 = a.inject(0) {|sum, c| sum + c}
  sum2 = b.inject(0) {|sum, c| sum + c}
  # summing up the squares
  sum1_sq = a.inject(0) {|sum, c| sum + c ** 2}
  sum2_sq = b.inject(0) {|sum, c| sum + c ** 2}
  # summing up the product
  prod_sum = a.zip(b).inject(0) {|sum, ab| sum + ab[0] * ab[1]}
  
  # calculating the Pearson score
  num = prod_sum - (sum1 *sum2 / n)  
  den = Math.sqrt((sum1_sq - (sum1 ** 2) / n) * (sum2_sq - (sum2 ** 2) / n))

  return 0 if den == 0
  return num / den  
end


puts pearson_score([1,2,3,4,5], [4,5,6,7,8])
# => 1.0
puts pearson_score([1,2,3,4,5], [4,5,0,7,8])
# => 0.5063696835418333
puts pearson_score([1,2,3,4,5], [4,5,0,7,7])
# => 0.4338609156373123
puts pearson_score([1,2,3,4,5], [8,7,6,5,4])
# => -1
{% endhighlight %}


## Manhattan Distance

There is no one size fits all and the formula you're going to use
depends on your data and what you want out of it.

For instance the
[Manhattan Distance](http://en.wikipedia.org/wiki/Taxicab_geometry)
computes the distance that would be traveled to get from one data
point to the other if a grid-like path is followed. I like this
graphic from Wikipedia that perfectly illustrates the difference with
Euclidean distance:

{% img center /assets/graphics/manhattan.png %}

Red, yellow and blue lines all have the same length and the distance
is bigger than the corresponding green diagonal, which is the normal
Euclidean distance.

Personally I haven't found a usage for it, as it is more related to
path-finding algorithms, but it's a good thing to keep in mind that it
exists and may prove useful. Since it measures how many changes you
have to do to your origin location to get to your destination while
being limited to taking small steps in a grid-like system, it is very
similar in spirit to the
[Levenshtein distance](http://en.wikipedia.org/wiki/Levenshtein_distance),
which measures the minimum number of changes required to transform
some text into another.

## Usage Sample

Checkout the *related/other articles* sections on this blog. It is how I've
solved the problem of lonely tags. Checkout this tag index page:
[SEO](/tags/SEO/).

Compare it with your average Wordpress tag index. Ain't this a lot
nicer? Yes, it's a Jekyll plugin. In case you want it for your own
Jekyll website, you can find the code in
[my repo](https://github.com/alexandru/bionicspirit.com/blob/master/source/_plugins/01-related-pages.rb)
(drop it in a directory called _plugins).

So you see, you don't have to work at Google-scale to take advantage
of such techniques.
