require "nokogiri"
require "cgi"

def to_absolute_url(site, url)
  if url =~ /^\//
    site['url'] + site['baseurl'] + url
  else
    url
  end
end

module Jekyll
  module MyUsefulFilters
    @@months = {
      '1': 'January',
      '2': 'February',
      '3': 'March',
      '4': 'April',
      '5': 'May',
      '6': 'June',
      '7': 'July',
      '8': 'August',
      '9': 'September',
      '10': 'October',
      '11': 'November',
      '12': 'December'
    }

    def toc_filter(toc_html, min_count=3)
      if toc_html.scan(/<li>/).count >= min_count
        toc_html.strip
      else 
        ""
      end
    end

    def date_to_long_string(date)
      parsed = time(date)
      m = @@months[parsed.strftime("%-m").to_sym]
      d = parsed.strftime("%-d")
      y = parsed.strftime("%Y")
      m + " " + d + ", " + y
    end

    def to_css_id(name)
      name.gsub(/\W+/, "_")
    end

    def xml_smart_escape(str)
      if !str
        str
      elsif str.match(/['"><]/) || (str.include?("&") && !str.match(/&\w+;/))
        CGI.escapeHTML(str)
      else
        str
      end
    end

    def calculate_related_articles(post, collection)
      related = []
      collection.each do |other|
        next if other.id == post.id
        score = ((other['tags'] || []) & (post['tags'] || [])).size
        ref2 = Hash['obj' => other, 'score' => score]
        related.push(ref2)
      end

      if related.size > 0
        related.sort { |a, b| -1 * (a['score'] <=> b['score'] || a['obj']['date'] <=> b['obj']['date']) }
          .map {|x| x['obj']}
      else
        []
      end
    end
  end

  module MyRSSFilter
    @@site = Jekyll.configuration({})

    def rss_campaign_link(link, medium=nil, content=nil)
      return link unless @@site['analytics']['enabled']

      l = if link.include? '?'
        link + "&"
      else
        link + "?"
      end

      l = l + "pk_source=rss"
      l = l + "&pk_medium=#{medium}" if medium and !medium.empty?
      l = l + "&pk_content=#{content}" if content and !content.empty?
      l
    end

    def rss_sort_all(posts)
      posts.sort { |a, b| 
        -1 * (
          a['date'] <=> b['date'] ||
          a['slug'] <=> b['slug']
        )
      }
    end

    def twitter_taggify(tag)
      tag.gsub(/\s+/, "")
    end

    def rss_process(html)
      doc = Nokogiri::HTML(html)

      doc.search(".hide-in-feed").remove

      doc.css("img").each do |elem|
        elem["src"] = to_absolute_url(@@site, elem['src'])
      end

      doc.css("a").each do |elem|
        elem["href"] = to_absolute_url(@@site, elem['href'])
      end

      doc.css("figcaption").each do |elem|
        elem.inner_html = "<p><em>" + elem.inner_html + "</em></p>"
      end

      doc.css("div.clear").each do |elem|
        elem["style"] = "clear: both; " + (elem["style"] || "") 
      end

      body = doc.at_css("body")
      body ? body.inner_html : ""
    end
  end
end

Liquid::Template.register_filter(Jekyll::MyUsefulFilters)
Liquid::Template.register_filter(Jekyll::MyRSSFilter)
