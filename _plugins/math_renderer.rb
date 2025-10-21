require 'digest'
require 'fileutils'
require 'json'
require 'open3'
require 'tmpdir'

module Jekyll
  class MathRenderer
    INLINE_MATH_REGEX = /\$([^\$]+)\$/
    DISPLAY_MATH_REGEX = /\$\$([^\$]+?)\$\$/m
    
    def initialize(site)
      @site = site
      # Use Jekyll's cache directory for generated math SVG files
      @math_dir = File.join(site.source, '.jekyll-cache', 'math-svg')
      @cache = {}
      @generated_files = {}
      FileUtils.mkdir_p(@math_dir)
    end
    
    def hash_formula(formula)
      Digest::MD5.hexdigest(formula.strip)
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
          'node', script_path, formula, @math_dir, inline_flag, "--optimize"
        )
        
        unless status.success?
          Jekyll.logger.error "MathRenderer:", "Failed to render formula: #{formula}"
          Jekyll.logger.error "MathRenderer:", stderr
          return formula # Return original formula on error
        end
      end
      
      # Track generated file for later addition to static_files
      @generated_files[filename] = filepath
      
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
        alt_text = escape_html(formula)
        svg_path = render_formula(formula, false)
        %(<div class="math-display page-width"><img src="#{svg_path}" alt="#{alt_text}" title="#{alt_text}" /></div>)
      end
      
      # Process inline math
      content = content.gsub(INLINE_MATH_REGEX) do |match|
        formula = $1.strip
        alt_text = escape_html(formula)
        svg_path = render_formula(formula, true)
        %(<img src="#{svg_path}" alt="#{alt_text}" title="#{alt_text}" class="math-inline" />)
      end
      
      content
    end
    
    def add_static_files
      @generated_files.each do |filename, filepath|
        file = MathStaticFile.new(
          @site,
          @math_dir,
          '',
          filename
        )
        @site.static_files << file
      end
    end
  end
  
  # Custom StaticFile class for math SVG files
  class MathStaticFile < Jekyll::StaticFile
    def initialize(site, base, dir, name)
      super(site, base, dir, name)
      @relative_path = File.join('/assets/math', name)
    end
    
    def destination(dest)
      File.join(dest, 'assets', 'math', @name)
    end
    
    def destination_rel_dir
      File.dirname(@relative_path)
    end
    
    def path
      # Override path to return the actual file location for size_of to work
      File.join(@base, @name)
    end
  end
  
  # Hook to initialize the renderer early
  Jekyll::Hooks.register :site, :post_read do |site|
    site.config['math_renderer'] = MathRenderer.new(site)
  end
  
  # Hook to process pages and posts
  Jekyll::Hooks.register [:pages, :posts, :documents], :pre_render do |doc|
    # Only process documents that have mathjax enabled
    if doc.data['mathjax']
      site = doc.site
      renderer = site.config['math_renderer']
      doc.content = renderer.process_content(doc.content)
    end
  end
  
  # Hook to add generated SVG files to static_files after content is processed
  Jekyll::Hooks.register :site, :post_render do |site|
    if site.config['math_renderer']
      renderer = site.config['math_renderer']
      renderer.add_static_files
    end
  end
end
