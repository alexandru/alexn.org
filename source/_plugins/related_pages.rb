# 
# Jekyll Plugin with a better algorithm for calculating 
# Related Posts.
#
# Relies on Cosine Similarity of post categories. See this Wikipedia
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

    all_categories = []
    per_post = {}

    posts.each do |post|
      per_post[post] ||= {}
      post.categories.each do |category|
        all_categories << category unless all_categories.member? category
        per_post[post][category] = 1
      end
    end

    # building points
    all_categories = all_categories.sort
    all_articles = []

    # dotprod = this_point.zip(that_point).map{|x| x[0] * x[1]}.inject(:+)
    # maga = Math.sqrt(this_point.map{|x| x ** 2}.inject(:+))
    # magb = Math.sqrt(that_point.map{|x| x ** 2}.inject(:+))
    # similarity = dot

    this_point = all_categories.map{|x| self.categories.member?(x) ? 1 : 0}
    posts.each do |post|
      next if post.categories.member? 'Deprecated'
      that_point = all_categories.map{|x| post.categories.member?(x) ? 1 : 0}
      
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
      (b[0] <=> a[0]) || (b[1].date <=> a[1].date) 
    }.map{|x| x[1]}.find_all{|x| x != self}
  end
end

module Jekyll
  class Post
    include RelatedPosts
  end
end
