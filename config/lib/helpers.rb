require "nokogiri"

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

  doc.at_css("body").inner_html
end
