module Jekyll
  class AssetLinkTag < Liquid::Tag

    def initialize(tag_name, path, tokens)
      super
      @path = path.strip
    end

    def render(context)
      path = @path
      assets_domain = context.environments[0]['site']['assets_domain']     
      path = "//" + assets_domain + path if path =~ /^\/[^\/]/ and assets_domain
      path
    end

  end
end

Liquid::Template.register_tag('asset_link', Jekyll::AssetLinkTag)
