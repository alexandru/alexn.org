require 'digest/md5'

module Jekyll
  class PathWithMD5 < Liquid::Tag

    def initialize(tag_name, path, tokens)
      super
      @path = path.strip
    end

    def render(context)
      path = @path
      abspath = File.join(File.dirname(__FILE__), '..', path[1..-1])

      if File.exists? abspath
        md5 = Digest::MD5.hexdigest(File.read(abspath))
        query = "?ck=#{md5}"
      else
        query = ''
      end

      if path.start_with? "/assets/"
        config = YAML::load_file(File.join(File.dirname(__FILE__), '..', '..', '_config.yml'))
        path = "//" + config['assets_domain'] + path if config['assets_domain']
      end

      path + query
    end

  end
end

Liquid::Template.register_tag('path_with_md5', Jekyll::PathWithMD5)
