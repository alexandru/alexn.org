require 'net/http'

module Jekyll
  module VideoLinks
    def youtube_thumb_link(uid, min_width=1200)
      "https://img.youtube.com/vi/#{uid}/maxresdefault.jpg"
    end

    def youtube_link(uid)
      "https://www.youtube.com/watch?v=#{uid}"
    end

    def youtube_player_link(uid)
      "https://www.youtube-nocookie.com/embed/#{uid}"
    end
  end
end

Liquid::Template.register_filter(Jekyll::VideoLinks)
