require "fastimage"

module MyImages
  @@site = Jekyll.configuration({})
  @@image_cache = {}
  
  def self.size_of(path, log=false)
    local_path = "." + path.gsub(/^#{Regexp.quote(@@site['baseurl'])}|[?][^$]+$/, "")
    local_path = local_path.sub("/wiki/assets/", "/_wiki/assets/")
    unless @@image_cache.include? local_path
      unless File.exist? local_path
        throw ArgumentError.new("Cannot find image at path: '#{local_path}'")
      end
      @@image_cache[local_path] = FastImage.size(local_path)
      puts "MyImages::size_of — Not cached: #{local_path}" if log
    else 
      puts "MyImages::size_of — Cached: #{local_path}" if log
    end
    @@image_cache[local_path]
  end
end

module Jekyll
  module MyImageFilters 
    def fix_images(html)
      html.gsub(/<img([^>]+)src=(['"](\/[^'"]+)['"])([^>]+)>/) do |img| 
        if img.include?("width=") || img.include?("height=")
          img
        else 
          prefix = Regexp.last_match[1]
          img0 = Regexp.last_match[2]
          path = Regexp.last_match[3]
          suffix = Regexp.last_match[4]
          
          size = MyImages.size_of(path)
          width = size[0]
          height = size[1]
          "<img#{prefix}src=#{img0} width=\"#{width}\" height=\"#{height}\"#{suffix}>"
        end 
      end
    end
  end
end
  
Liquid::Template.register_filter(Jekyll::MyImageFilters)
