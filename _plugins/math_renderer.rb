require 'digest'
require 'fileutils'
require 'json'
require 'open3'

module Jekyll
  class MathRenderer
    INLINE_MATH_REGEX = /\$([^\$]+)\$/
    DISPLAY_MATH_REGEX = /\$\$([^\$]+?)\$\$/m
    
    def initialize(site)
      @site = site
      @math_dir = File.join(site.source, 'assets', 'math')
      @cache = {}
      FileUtils.mkdir_p(@math_dir)
    end
    
    def hash_formula(formula)
      Digest::MD5.hexdigest(formula)
    end
    
    def render_formula(formula, inline = false)
      hash = hash_formula(formula)
      filename = "#{hash}.svg"
      filepath = File.join(@math_dir, filename)
      
      # Return cached result if available
      return @cache[hash] if @cache.key?(hash)
      
      # Generate SVG if it doesn't exist
      unless File.exist?(filepath)
        script_path = File.join(@site.source, 'scripts', 'tex2svg.js')
        inline_flag = inline ? '--inline' : ''
        
        stdout, stderr, status = Open3.capture3(
          'node', script_path, formula, @math_dir, inline_flag
        )
        
        unless status.success?
          Jekyll.logger.error "MathRenderer:", "Failed to render formula: #{formula}"
          Jekyll.logger.error "MathRenderer:", stderr
          return formula # Return original formula on error
        end
      end
      
      # Cache and return the result
      svg_path = "/assets/math/#{filename}"
      @cache[hash] = svg_path
      svg_path
    end
    
    def escape_html(str)
      str.gsub('&', '&amp;')
         .gsub('<', '&lt;')
         .gsub('>', '&gt;')
         .gsub('"', '&quot;')
         .gsub("'", '&#39;')
    end
    
    def process_content(content)
      # Process display math first (to avoid conflicts with inline math)
      content = content.gsub(DISPLAY_MATH_REGEX) do |match|
        formula = $1.strip
        svg_path = render_formula(formula, false)
        %(<img src="#{svg_path}" alt="#{escape_html(formula)}" class="math-display" />)
      end
      
      # Process inline math
      content = content.gsub(INLINE_MATH_REGEX) do |match|
        formula = $1.strip
        svg_path = render_formula(formula, true)
        %(<img src="#{svg_path}" alt="#{escape_html(formula)}" class="math-inline" />)
      end
      
      content
    end
  end
  
  # Hook to process pages and posts
  Jekyll::Hooks.register [:pages, :posts, :documents], :pre_render do |doc|
    # Only process documents that have mathjax enabled
    if doc.data['mathjax']
      site = doc.site
      renderer = site.config['math_renderer'] ||= MathRenderer.new(site)
      doc.content = renderer.process_content(doc.content)
    end
  end
end
