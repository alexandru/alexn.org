require 'net/http'

module Jekyll
  module VideoLinks
    @@_vimeo_cache = {}

    def vimeo_link(uid)
      "https://vimeo.com/#{uid}"
    end

    def vimeo_player_link(uid)
      "https://player.vimeo.com/video/#{uid}?title=0&byline=0&portrait=0&dnt=1"
    end

    def vimeo_thumb_link(uid, min_width=1200)
      get_vimeo_thumb_link(uid, min_width, false)
    end

    def vimeo_thumb_play_link(uid, min_width=1200)
      get_vimeo_thumb_link(uid, min_width, true)
    end

    def youtube_thumb_link(uid, min_width=1200)
      "https://img.youtube.com/vi/#{uid}/maxresdefault.jpg"
    end

    def youtube_link(uid)
      "https://www.youtube.com/watch?v=#{uid}"
    end

    def youtube_player_link(uid)
      "https://www.youtube-nocookie.com/embed/#{uid}"
    end

    def warn(msg)
      if defined? Jekyll
        Jekyll.logger.warn(msg)
      else
        STDERR.puts msg
      end
    end
    
    def get_vimeo_thumb_link(uid, min_width=1200, with_play=false)
      key = "#{uid}-#{min_width}-#{with_play}"
      if @@_vimeo_cache.has_key? key
        return @@_vimeo_cache[key]
      end

      Jekyll.logger.info("             Vimeo: Fetching thumb link for #{uid}")
      link = get_vimeo_thumb_link_raw(uid, min_width, with_play)
      @@_vimeo_cache[key] = link
      return link
    end

    def get_vimeo_thumb_link_raw(uid, min_width=1200, with_play=false)
      unless ENV['VIMEO_API_TOKEN']
        warn("WARNING — VIMEO_API_TOKEN not set, querying low-resolution thumbnail for https://vimeo.com/#{uid}")
        response = Net::HTTP.get URI("https://vimeo.com/api/v2/video/#{uid}.json")
        json = JSON.parse(response)
        if json.length > 0 
          return json[0]['thumbnail_large']
        end
      else
        response = Net::HTTP.get URI("https://api.vimeo.com/videos/#{uid}/pictures/?access_token=#{ENV['VIMEO_API_TOKEN']}&per_page=100")
        json = JSON.parse(response)
        sizes = begin
          json['data'][0]['sizes'].sort_by {|x| x['width'] }
        rescue
          []
        end
    
        elem = sizes.detect {|x| x['width'] >= min_width }
        unless elem
          elem = sizes.last
        end
    
        if elem
          if with_play
            return elem['link_with_play_button']
          else
            return elem['link']
          end
        end
    end
      warn("WARNING — couldn't find thumbnail for video: https://vimeo.com/#{uid}")
      return nil
    end
  end
end

Liquid::Template.register_filter(Jekyll::VideoLinks)
