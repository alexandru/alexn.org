module Utils

  def self.wrap_assets_link(path, site=nil)
    return path unless path =~ /\/[^\/]/

    if not site
      require 'yaml'
      config = YAML::load(File.read File.join(File.dirname(__FILE__), '..', '..', '_config.yml'))
    elsif site.respond_to? :[]
      config = site
    end

    domains = config['assets_domains'] || []
    return path unless domains and domains.length > 0

    domain = domains[path.hash % domains.length]
    "//#{domain}#{path}"
  end

end
