require 'cgi'
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
      # Use Jekyll's cache directory for generated math files
      @math_dir = File.join(site.source, '.jekyll-cache', 'math')
      @generated_files = {}
      FileUtils.mkdir_p(@math_dir)
    end
    
    def hash_formula(formula)
      Digest::MD5.hexdigest(formula.strip)
    end
    
    def escape_html(str)
      CGI.escapeHTML(str).gsub(/\s+/, ' ')
    end
    
    def collect_formulas(content)
      formulas = []
      
      # Collect display math formulas
      content.scan(DISPLAY_MATH_REGEX) do |match|
        formulas << { formula: match[0].strip, inline: false }
      end
      
      # Collect inline math formulas
      content.scan(INLINE_MATH_REGEX) do |match|
        formulas << { formula: match[0].strip, inline: true }
      end
      
      formulas
    end
    
    def process_formulas_batch(formulas)
      return if formulas.empty?
      
      script_path = File.join(@site.source, 'scripts', 'tex2svg.js')
      json_input = formulas.to_json
      
      stdout, stderr, status = Open3.capture3(
        'node', script_path, json_input, @math_dir
      )
      
      unless status.success?
        Jekyll.logger.error "MathRenderer:", "Failed to render formulas"
        Jekyll.logger.error "MathRenderer:", stderr
        return
      end
      
      # Parse the results
      begin
        results = JSON.parse(stdout)
        results.each do |result|
          next if result['error']
          
          hash = result['hash']
          svg_filename = result['svgFilename']
          
          # Track generated SVG file for static_files
          svg_filepath = File.join(@math_dir, 'svg', svg_filename)
          @generated_files[svg_filename] = svg_filepath
        end
      rescue JSON::ParserError => e
        Jekyll.logger.error "MathRenderer:", "Failed to parse results: #{e.message}"
      end
    end
    
    def process_content(content)
      # Collect all formulas first
      formulas = collect_formulas(content)
      
      # Process all formulas in batch
      process_formulas_batch(formulas)
      
      # Replace display math
      content = content.gsub(DISPLAY_MATH_REGEX) do |match|
        formula = $1.strip
        hash = hash_formula(formula)
        filename = "#{hash}.svg"
        svg_filepath = File.join(@math_dir, 'svg', filename)
        
        # Get size if file exists
        if File.exist?(svg_filepath)
          size = FastImage.size(svg_filepath)
          svg_path = "/assets/math/#{filename}"
          alt_text = escape_html(formula)
          %(<div class="math-display page-width"><img src="#{svg_path}" alt="Math formula" title="#{alt_text}" width="#{size[0] * 12}" height="#{size[1] * 12}" loading="lazy" data-math-hash="#{hash}" /></div>)
        else
          Jekyll.logger.warn "MathRenderer:", "SVG not found for formula: #{formula}"
          match # Return original if rendering failed
        end
      end
      
      # Replace inline math
      content = content.gsub(INLINE_MATH_REGEX) do |match|
        formula = $1.strip
        hash = hash_formula(formula)
        filename = "#{hash}.svg"
        svg_filepath = File.join(@math_dir, 'svg', filename)
        
        # Get size if file exists
        if File.exist?(svg_filepath)
          size = FastImage.size(svg_filepath)
          svg_path = "/assets/math/#{filename}"
          alt_text = escape_html(formula)
          %(<img src="#{svg_path}" alt="Math formula" title="#{alt_text}" class="math-inline" width="#{size[0] * 12}" height="#{size[1] * 12}" loading="lazy" data-math-hash="#{hash}" />)
        else
          Jekyll.logger.warn "MathRenderer:", "SVG not found for formula: #{formula}"
          match # Return original if rendering failed
        end
      end
      
      content
    end
    
    def add_static_files
      svg_dir = File.join(@math_dir, 'svg')
      
      @generated_files.each do |filename, filepath|
        # Add SVG file to static_files
        file = MathStaticFile.new(
          @site,
          svg_dir,
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
      # Override path to return the actual file location
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
