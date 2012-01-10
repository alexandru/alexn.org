require 'sass'

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

      chk = site.time.to_s.gsub(/\W+/, '')      
      all_css = dest.join('assets', "all-#{chk}.css")
      all_css.dirname.mkpath unless all_css.dirname.exist?
      File.open(all_css, 'w') do |fh|
        fh.write(all_content)
      end

      site.static_files << Jekyll::AllCSSFile.new(site, site.dest, 'assets', "all-#{chk}.css")
    end    
  end

  class AllCSSTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
    end

    def render(context)
      chk = context.environments[0]['site']['time'].to_s.gsub(/\W+/, '')
      assets_domain = context.environments[0]['site']['assets_domain']

      path = "/assets/all-#{chk}.css"
      path = "http://#{assets_domain}#{path}" if assets_domain

      return path
    end
  end
end

Liquid::Template.register_tag('all_css_path', Jekyll::AllCSSTag)

