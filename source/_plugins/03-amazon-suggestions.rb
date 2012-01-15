require 'yaml'
require 'ostruct'

module Jekyll
  class AmazonBookTag < Liquid::Block
    def initialize(tag_name, text, tokens)
      super
    end

    def self.data
      unless @data 
        @data = YAML::load(File.read File.join(File.dirname(__FILE__), '..', 'data', 'amazon-books.yml'))
      end
      @data
    end

    def render(context)
      return '' unless context['page']['has_ads']

      tags = context['page']['tags']
      items = AmazonBookTag.data.map{|x| OpenStruct.new x}

      sorted = RelatedPosts.sort_on_similarity(tags, items)
      return '' unless sorted && sorted.length > 1

      book = Hash[sorted[0].marshal_dump.map{|key, value| [key.to_s, value]}]
      book['image'] = Utils.wrap_assets_link(book['image'], context['site'])

      result = ''
      context.stack do        
        context['book'] = book
        result << render_all(@nodelist, context).join
      end

      return result
    end
  end
end

Liquid::Template.register_tag('amazonbook', Jekyll::AmazonBookTag)

