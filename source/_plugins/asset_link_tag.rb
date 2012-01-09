require 'yaml'

module Jekyll
  class AssetLinkTag < Liquid::Tag

    def initialize(tag_name, path, tokens)
      super
      @path = path.strip
    end

    def render(context)
      path = @path
      if path.start_with? "/"
        config = YAML::load_file(File.join(File.dirname(__FILE__), '..', '..', '_config.yml'))
        path = "//" + config['assets_domain'] + path if config['assets_domain']
      end
      return path
    end

  end
end

Liquid::Template.register_tag('asset_link', Jekyll::AssetLinkTag)
