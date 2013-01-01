require_relative 'utils'

module Jekyll
  class AssetLinkTag < Liquid::Tag

    def initialize(tag_name, path, tokens)
      super
      @path = path.strip
    end

    def render(context)
      Utils.wrap_assets_link(@path, context['site'])
    end

  end
end

Liquid::Template.register_tag('asset_link', Jekyll::AssetLinkTag)
