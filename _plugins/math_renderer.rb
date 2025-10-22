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
      # Use Jekyll's cache directory for generated math SVG files
      @math_dir = File.join(site.source, '.jekyll-cache', 'math-svg')
      @cache = {}
      @generated_files = {}
      @pending_formulas = []
      FileUtils.mkdir_p(@math_dir)
    end
    
    def hash_formula(formula)
      Digest::MD5.hexdigest(formula.strip)
    end
    
    def render_formula(formula, inline = false)
      hash = hash_formula(formula)
      filename = "#{hash}.svg"
      
      # Use the transparent SVG by default (for website)
      transparent_dir = File.join(@math_dir, 'transparent')
      white_dir = File.join(@math_dir, 'white')
      
      transparent_filepath = File.join(transparent_dir, filename)
      white_filepath = File.join(white_dir, filename)
      
      # Return cached result if available
      return @cache[hash] if @cache.key?(hash)
      
      # Check if files already exist (from previous build)
      if File.exist?(transparent_filepath) && File.exist?(white_filepath)
        # Track both generated files for later addition to static_files
        @generated_files["transparent/#{filename}"] = transparent_filepath
        @generated_files["white/#{filename}"] = white_filepath
        
        # Cache and return the transparent version result (for website)
        size = FastImage.size(transparent_filepath)
        svg_path = "/assets/math/transparent/#{filename}"
        @cache[hash] = [svg_path, size]
        return @cache[hash]
      end
      
      # Queue formula for batch processing
      @pending_formulas << { formula: formula, inline: inline, hash: hash }
      
      # Return placeholder that will be populated after batch processing
      @cache[hash] = nil
      nil
    end
    
    def process_pending_formulas
      return if @pending_formulas.empty?
      
      Jekyll.logger.info "MathRenderer:", "Processing #{@pending_formulas.length} formulas in batch..."
      
      script_path = File.join(@site.source, 'scripts', 'tex2svg.js')
      
      # Prepare input data for batch processing
      formulas_data = @pending_formulas.map { |f| { formula: f[:formula], inline: f[:inline] } }
      input_json = JSON.generate(formulas_data)
      
      # Call the batch processing script
      stdout, stderr, status = Open3.capture3(
        'node', script_path, '--batch', @math_dir,
        stdin_data: input_json
      )
      
      unless status.success?
        Jekyll.logger.error "MathRenderer:", "Batch processing failed"
        Jekyll.logger.error "MathRenderer:", stderr
        # Fall back to individual processing
        @pending_formulas.each do |pending|
          process_single_formula(pending[:formula], pending[:inline])
        end
        @pending_formulas.clear
        return
      end
      
      # Process results
      begin
        results = JSON.parse(stdout)
        results.each do |result|
          if result['success']
            hash = result['hash']
            filename = result['filename']
            
            transparent_filepath = File.join(@math_dir, 'transparent', filename)
            white_filepath = File.join(@math_dir, 'white', filename)
            
            # Track both generated files for later addition to static_files
            @generated_files["transparent/#{filename}"] = transparent_filepath
            @generated_files["white/#{filename}"] = white_filepath
            
            # Update cache with the results
            if File.exist?(transparent_filepath)
              size = FastImage.size(transparent_filepath)
              svg_path = "/assets/math/transparent/#{filename}"
              @cache[hash] = [svg_path, size]
            end
          else
            Jekyll.logger.warn "MathRenderer:", "Failed to render: #{result['formula']}"
          end
        end
      rescue JSON::ParserError => e
        Jekyll.logger.error "MathRenderer:", "Failed to parse batch results: #{e.message}"
      end
      
      @pending_formulas.clear
    end
    
    def process_single_formula(formula, inline)
      hash = hash_formula(formula)
      filename = "#{hash}.svg"
      
      transparent_dir = File.join(@math_dir, 'transparent')
      white_dir = File.join(@math_dir, 'white')
      
      transparent_filepath = File.join(transparent_dir, filename)
      white_filepath = File.join(white_dir, filename)
      
      script_path = File.join(@site.source, 'scripts', 'tex2svg.js')
      inline_flag = inline ? '--inline' : ''
      
      stdout, stderr, status = Open3.capture3(
        'node', script_path, formula, @math_dir, inline_flag
      )
      
      unless status.success?
        Jekyll.logger.error "MathRenderer:", "Failed to render formula: #{formula}"
        Jekyll.logger.error "MathRenderer:", stderr
        return
      end
      
      # Track both generated files
      @generated_files["transparent/#{filename}"] = transparent_filepath
      @generated_files["white/#{filename}"] = white_filepath
      
      # Update cache
      if File.exist?(transparent_filepath)
        size = FastImage.size(transparent_filepath)
        svg_path = "/assets/math/transparent/#{filename}"
        @cache[hash] = [svg_path, size]
      end
    end

    def escape_html(str)
      CGI.escapeHTML(str).gsub(/\s+/, ' ')
    end
    
    def process_content(content)

      # First pass: collect all formulas and check/queue them for processing
      # Process display math first (to avoid conflicts with inline math)
      display_formulas = []
      content.scan(DISPLAY_MATH_REGEX) do |match|
        formula = match[0].strip
        display_formulas << formula
        render_formula(formula, false)
      end
      
      # Process inline math
      inline_formulas = []
      content.scan(INLINE_MATH_REGEX) do |match|
        formula = match[0].strip
        inline_formulas << formula
        render_formula(formula, true)
      end
      
      # Batch process any pending formulas
      process_pending_formulas
      
      # Second pass: replace formulas with rendered HTML
      # Process display math first (to avoid conflicts with inline math)
      content = content.gsub(DISPLAY_MATH_REGEX) do |match|
        formula = $1.strip
        alt_text = escape_html(formula)
        result = @cache[hash_formula(formula)]
        if result
          svg_path, size = result
          %(<div class="math-display page-width"><img src="#{svg_path}" alt="Math formula" title="#{alt_text}" width="#{size[0] * 12}" height="#{size[1] * 12}" loading="lazy" /></div>)
        else
          # Fallback to original if rendering failed
          match
        end
      end
      
      # Process inline math
      content = content.gsub(INLINE_MATH_REGEX) do |match|
        formula = $1.strip
        alt_text = escape_html(formula)
        result = @cache[hash_formula(formula)]
        if result
          svg_path, size = result
          %(<img src="#{svg_path}" alt="Math formula" title="#{alt_text}" class="math-inline" width="#{size[0] * 12}" height="#{size[1] * 12}" loading="lazy" />)
        else
          # Fallback to original if rendering failed
          match
        end
      end
      
      content
    end
    
    def add_static_files
      @generated_files.each do |rel_path, filepath|
        # The filepath already contains the correct full path to the file
        # Extract directory components to create the correct MathStaticFile
        dir_parts = rel_path.split(File::SEPARATOR)
        base_name = dir_parts.last
        
        if dir_parts.length > 1
          # For files in subdirectories (transparent or white)
          subdir = dir_parts.first
          parent_dir = File.dirname(filepath)  # Path to the parent directory
          
          file = MathStaticFile.new(
            @site,
            parent_dir,  # Base directory is parent dir of the file
            '',  # Empty string as dir since we handle this in name
            base_name,
            subdir  # Pass the subdirectory as a parameter
          )
        else
          # Legacy case - files directly in math_dir
          file = MathStaticFile.new(
            @site,
            @math_dir,
            '',
            rel_path
          )
        end
        
        @site.static_files << file
      end
    end
  end
  
  # Custom StaticFile class for math SVG files
  class MathStaticFile < Jekyll::StaticFile
    def initialize(site, base, dir, name, subdir = nil)
      super(site, base, dir, name)
      @subdir = subdir
      
      if @subdir
        # If we have a subdirectory specified
        @relative_path = File.join('/assets/math', @subdir, name)
      else
        # Backwards compatibility case
        @relative_path = File.join('/assets/math', name)
      end
    end
    
    def destination(dest)
      if @subdir
        # If we have a subdirectory
        File.join(dest, 'assets', 'math', @subdir, @name)
      else
        # Backwards compatibility case
        File.join(dest, 'assets', 'math', @name)
      end
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
