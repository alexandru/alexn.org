require 'cgi'
require 'digest'
require 'fileutils'
require 'json'
require 'open3'
require 'tmpdir'

module Jekyll
  class MathRenderer
    MATH_REGEX = /(\$\$)([^\$]+?)\1|(?<!\$)(\$)([^\$\r\n]+)\3(?!\$)/m
    
    def initialize(site)
      @site = site
      # Use Jekyll's cache directory for generated math SVG files
      @math_dir = File.join(site.source, '.jekyll-cache', 'math-svg')
      @cache = {}
      @generated_files = {}
      @pending_formulas = []
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
      @pending_formulas << { 
        formula: formula, 
        inline: inline, 
        hash: hash,
        path: File.join(@math_dir, "#{hash}.svg")
      }
      
      # Return placeholder that will be populated after batch processing
      @cache[hash] = nil
      nil
    end

    def call_process_script(formulas)
      already_existing, missing = 
        formulas.partition { |f| File.exist?(f[:path]) }
      formulas_data = missing
        .map { |f| { formula: f[:formula], inline: f[:inline] } }
      
      if formulas_data.length > 0
        input_json = JSON.generate(formulas_data)
        
        FileUtils.mkdir_p(@math_dir)
        script_path = File.join(@site.source, 'scripts', 'tex2svg.js')
        stdout, stderr, status = Open3.capture3(
          'node', script_path, '--batch', @math_dir,
          stdin_data: input_json
        )
        unless status.success?
          Jekyll.logger.error "MathRenderer:", "Batch processing failed"
          Jekyll.logger.error "MathRenderer:", stderr
          raise "MathRenderer batch processing failed: #{stderr}"
        end
        results = JSON.parse(stdout)
      else 
        results = []
      end

      already_existing.each do |f|
        results << {
          "formula": f[:formula],
          "inline": f[:inline],
          "success": true
        }
      end
    end
    
    def process_pending_formulas
      return if @pending_formulas.empty?
      
      Jekyll.logger.info "MathRenderer:", "Processing #{@pending_formulas.length} formulas in batch..."
      
      # Prepare input data for batch processing
      results = call_process_script(@pending_formulas)
      @pending_formulas.clear
      
      # Process results
      begin
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
      matches, parts = split_with_matches(content, MATH_REGEX)
      if !matches || matches.length == 0
        return content
      end

      matches.each do |match|
        formula = (match[2] || match[4]).strip
        is_inline = !!match[3]
        render_formula(formula, is_inline)
      end

      # Batch process any pending formulas
      process_pending_formulas
      
      new_content = []
      parts.each do |part|
        has_formula = part.match(/^\s*([\$]+)/)
        if has_formula
          is_inline = has_formula[1] == "$"
          formula = part.gsub(/^\s*[\$]+\s*|\s*[\$]+\s*$/, "")
          alt_text = escape_html(formula)
          result = @cache[hash_formula(formula)]
          if result
            svg_path, size = result
            if !is_inline
              new_content << %(<div class="math-display page-width"><img src="#{svg_path}" alt="Math formula" title="#{alt_text}" width="#{size[0] * 12}" height="#{size[1] * 12}" loading="lazy" /></div>)
            else 
              new_content << %(<img src="#{svg_path}" alt="Math formula" title="#{alt_text}" class="math-inline" width="#{size[0] * 12}" height="#{size[1] * 12}" loading="lazy" />)
            end
          else
            new_content << part
          end
        else 
          new_content << part
        end
      end

      new_content.join("")
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

    def split_with_matches(text, regex)
      parts = []
      matches = []
      position = 0

      text.scan(regex) do |match|
        md = Regexp.last_match
        # Add text before the match
        parts << text[position...md.begin(0)]
        # Add the match itself
        parts << md[0]
        matches << md
        position = md.end(0)
      end
      
      # Add remaining text after last match
      parts << text[position..-1]
      
      [matches, parts.reject(&:empty?)]
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
