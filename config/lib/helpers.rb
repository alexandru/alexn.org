require "nokogiri"
require 'fastimage'

def website
  @website_ref = @website_ref || OpenStruct.new(YAML::load_file(File.dirname(__FILE__) + "/../config.yaml")[:website])
  @website_ref
end

def with_image_url(html, want_dimensions)
  doc = Nokogiri::HTML(html)
  img = doc.css("img").first
  if img
    url = img["src"]
  else
    url = "/assets/img/logo.png"
  end

  # trying to find width and height
  width = height = nil
  if want_dimensions
    if url.start_with?("/")
      img_path = "./source" + url
    else
      img_path = url
    end

    if img_path
      begin
        width, height = FastImage.size(img_path)
      rescue
      end
    end
  end

  url = website.root_url + url unless url.start_with?("http")
  if want_dimensions
    yield(url, width, height)
  else
    yield(url)
  end
end

def rss_summary_of(html)
  html = html.split(/<![-][-]\s*read\s*more\s*[-][-]>/)[0]
  doc = Nokogiri::HTML(html)

  doc.css("h1").each{|elem|
    elem["style"] = "font-size: 180%; font-weight: bold;"
    elem.inner_html = "<b>" + elem.inner_html + "<b>"
  }
  doc.css("h2").each{|elem|
    elem["style"] = "font-size: 150%; font-weight: bold;"
    elem.inner_html = "<b>" + elem.inner_html + "<b>"
  }
  doc.css("h3").each{|elem|
    elem["style"] = "font-size: 120%; font-weight: bold;"
    elem.inner_html = "<b>" + elem.inner_html + "<b>"
  }

  doc.css("img[class=right]").each{|elem|
    elem["style"] = "float: right; margin-left: 10px; margin-bottom: 10px;"
    elem["align"] = "right"
  }

  doc.css("img[class=left]").each{|elem|
    elem["style"] = "float: left; margin-right: 10px; margin-bottom: 10px;"
    elem["align"] = "left"
  }

  doc.css("img").each{|elem|
    sep = elem["style"] !~ /;\s*$/ ? "; " : ""
    if elem["width"] && elem["style"] !~ /width[:]/
      elem["style"] += sep + "width: " + elem["width"] + "px; " 
    end 
    if elem["height"] && elem["style"] !~ /height[:]/
      elem["style"] += sep + "height: " + elem["height"] + "px; "
    end
  }

  doc.at_css("body").inner_html
end
