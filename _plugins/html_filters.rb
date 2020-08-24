require "nokogiri"

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
  end

  module MyRSSFilter
    @@site = Jekyll.configuration({})

    def rss_campaign_link(link, keyword)
      l = if link.include? '?'
        link + "&"
      else
        link + "?"
      end

      l = l + "pk_campaign=rss"
      l = l + "&pk_kwd=" + keyword if keyword
      l
    end

    def rss_process(html)
      doc = Nokogiri::HTML(html)

      doc.css("img").each do |elem|
        elem["src"] = to_absolute_url(@@site, elem['src'])
        elem["style"] = "max-width: 100%; " + (elem["style"] || "")
      end

      doc.css("img.left").each do |elem|
        elem["src"] = to_absolute_url(@@site, elem['src'])
        elem["style"] = "float:left; margin-right:20px; margin-bottom:20px;" + (elem["style"] || "")
      end

      doc.css("img.right").each do |elem|
        elem["src"] = to_absolute_url(@@site, elem['src'])
        elem["style"] = "float:right; margin-left:20px; margin-left:20px;" + (elem["style"] || "")
      end

      doc.css("iframe").each do |elem|
        elem["style"] = "max-width: 100%; " + (elem["style"] || "")
      end

      doc.css("figure").each do |elem|
        elem["style"] = "max-width: 100%; " + (elem["style"] || "")
      end

      doc.css("a").each do |elem|
        elem["href"] = to_absolute_url(@@site, elem['href'])
      end

      doc.css("figcaption").each do |elem|
        elem.inner_html = "<p><em>" + elem.inner_html + "</em></p>"
      end

      body = doc.at_css("body")
      body ? doc.at_css("body").inner_html : ""
    end
  end
end

Liquid::Template.register_filter(Jekyll::MyUsefulFilters)
Liquid::Template.register_filter(Jekyll::MyRSSFilter)
