# 
# Jekyll Plugin with a better algorithm for calculating 
# Related Posts.
#
# Relies on Cosine Similarity of post tags. See this Wikipedia
# reference: http://en.wikipedia.org/wiki/Cosine_similarity
#

require 'jekyll/post'

module RelatedPosts
  def self.included(klass)
    klass.class_eval do
      remove_method :related_posts
    end
  end

  def related_posts(posts)
    return [] unless posts.size > 1

    all_tags = []
    per_post = {}

    posts.each do |post|
      per_post[post] ||= {}
      post.tags.each do |tag|
        all_tags << tag unless all_tags.member? tag
        per_post[post][tag] = 1
      end
    end

    # building points
    all_tags = all_tags.sort
    all_articles = []

    # dotprod = this_point.zip(that_point).map{|x| x[0] * x[1]}.inject(:+)
    # maga = Math.sqrt(this_point.map{|x| x ** 2}.inject(:+))
    # magb = Math.sqrt(that_point.map{|x| x ** 2}.inject(:+))
    # similarity = dot

    this_point = all_tags.map{|x| self.tags.member?(x) ? 1 : 0}
    posts.each do |post|
      next if post.tags.member? 'Deprecated'
      that_point = all_tags.map{|x| post.tags.member?(x) ? 1 : 0}
      
      dotp = this_point.zip(that_point).map{|x| x[0] * x[1]}.inject(:+)
      maga = Math.sqrt(this_point.map{|x| x ** 2}.inject(:+))
      magb = Math.sqrt(that_point.map{|x| x ** 2}.inject(:+))     
      similarity = dotp / (maga * magb)

      # calculating Euclidian distance      
      all_articles << [
        similarity,
        post
      ]
    end

    all_articles.sort{|a,b| 
      b[0] != a[0] ? b[0] <=> a[0] : b[1] <=> a[1]
    }.map{|x| x[1]}.find_all{|x| x != self}
  end
end

module Jekyll
  class Post
    include RelatedPosts
  end
end
