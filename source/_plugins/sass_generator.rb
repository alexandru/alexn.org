require 'sass'
require 'digest/md5'
require_relative 'utils'

module Jekyll

  class AllCSSFile < StaticFile
    def write(dest)
      super(dest) rescue ArgumentError
      true
    end
  end

  class AllCSSGenerator < Generator
    safe true
    priority :low

    def generate(site)
      source = Pathname(site.source)
      dest = Pathname(site.dest)

      all_content = ''

      files = Dir.entries(source.join('assets', 'stylesheets')).find_all {|x| x =~ /\d.*(\.scss|\.css)$/}.sort
      files.each do |fname|
        fpath = source.join('assets', 'stylesheets', fname).to_s
        content = File.read(fpath)

        if fpath =~ /\.scss$/
          begin
            engine = Sass::Engine.new(content, :syntax => :scss)
            content = engine.render
          rescue StandardError => e
            puts "!!! SASS Error: " + e.message
            content = ''
          end
        end

        all_content << content
      end      

      all_css = dest.join('assets', "all.css")
      all_css.dirname.mkpath unless all_css.dirname.exist?
      File.open(all_css, 'w') do |fh|
        fh.write(all_content)
      end

      digest_name = "all-" + Digest::MD5.hexdigest(all_content)[0,9] + ".css"
      digest_css = dest.join("assets", digest_name)
      File.open(digest_css, 'w') do |fh|
        fh.write(all_content)
      end

      site.static_files << Jekyll::AllCSSFile.new(site, site.dest, 'assets', "all.css")
      site.static_files << Jekyll::AllCSSFile.new(site, site.dest, 'assets', digest_name)
    end    
  end

  class AllCSSTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
    end

    def render(context)
      return '/assets/all.css' unless context['site']['build_type'] == 'production' and context['site']['css_hash'] == true
      path = File.join(File.dirname(__FILE__), '..', '..', 'build', 'assets', 'all.css')
      return Utils.wrap_assets_link("/assets/all.css", context['site'])
      #css = File.exists?(path) ? File.read(path) : Time.now.strftime("%Y%m%d")
      #Utils.wrap_assets_link("/assets/all-" + Digest::MD5.hexdigest(css)[0,9] + ".css", context['site'])
    end
  end
end

Liquid::Template.register_tag('all_css_path', Jekyll::AllCSSTag)

