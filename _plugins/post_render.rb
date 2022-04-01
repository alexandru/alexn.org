require 'json'

Jekyll::Hooks.register([:site], :post_write) do |post|
  all_redirects = JSON.parse(File.read("_site/redirects.json"))

  redirects_txt = all_redirects
    .map { |k,v| "#{k} #{v.gsub(/^https?:\/\/[^\/]+/, "")} 301" }
    .sort
    .join("\n")

  File.write(
    "_site/_redirects",
    File.read("_site/_redirects")
      .sub("# AUTOMATED redirect_from inclusions here <--", redirects_txt)
  )
  
  redirects_txt = all_redirects
    .map { |k,v| "    rewrite ^#{k}$ #{v.gsub(/^https?:\/\/[^\/]+/, "")} permanent;" }
    .sort
    .join("\n")
  
  File.write(
    "_site/nginx.conf",
    File.read("_site/nginx.conf")
      .sub("    # AUTOMATED redirect_from inclusions here <--", redirects_txt)
  )
end
