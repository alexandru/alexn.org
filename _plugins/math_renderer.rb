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
      # Use Jekyll's cache directory for generated MathML files
      @math_dir = File.join(site.source, '.jekyll-cache', 'math-mathml')
      @cache = {}
      FileUtils.mkdir_p(@math_dir)
    end
    
    def hash_formula(formula)
      Digest::MD5.hexdigest(formula.strip)
    end
    
    def render_formula(formula, inline = false)
      hash = hash_formula(formula)
      
      # Return cached result if available
      return @cache[hash] if @cache.key?(hash)
      
      filename = "#{hash}.mathml"
      filepath = File.join(@math_dir, filename)
      
      # Generate MathML if it doesn't exist
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
      
      # Read and cache the MathML content
      mathml_content = File.read(filepath)
      @cache[hash] = mathml_content
      mathml_content
    end
    

    def escape_html(str)
      CGI.escapeHTML(str).gsub(/\s+/, ' ')
    end
    
    def process_content(content)

      # Process display math first (to avoid conflicts with inline math)
      content = content.gsub(DISPLAY_MATH_REGEX) do |match|
        formula = $1.strip
        mathml_content = render_formula(formula, false)
        %(<div class="math-display page-width">#{mathml_content}</div>)
      end
      
      # Process inline math
      content = content.gsub(INLINE_MATH_REGEX) do |match|
        formula = $1.strip
        mathml_content = render_formula(formula, true)
        %(<span class="math-inline">#{mathml_content}</span>)
      end
      
      content
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
  
end
