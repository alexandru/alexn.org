module Utils

  def self.wrap_assets_link(path, site)
    return path if site['build_type'] != 'production' || path[0,1] != '/'
    
    domains = site['assets_domains'] || []
    return path unless domains && domains.length > 0

    domain = domains[path.hash % domains.length]
    "//#{domain}#{path}"
  end

end
