# 
# Jekyll Plugin with a better algorithm for calculating 
# Related Posts.
#
# Relies on Cosine Similarity of post tags. See this Wikipedia
# reference: http://en.wikipedia.org/wiki/Cosine_similarity
#

require 'jekyll/post'

module Jekyll
  class Post
    alias_method :old_related_posts, :related_posts
 
    def related_posts(posts)   
      old_related_posts(posts).find_all{|x| x != self && !x.data['archive']}
    end
  end
end
