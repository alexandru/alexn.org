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
      # Use Jekyll's cache directory for generated math MML files
      @math_dir = File.join(site.source, '.jekyll-cache', 'math-mml')
      @cache = {}
      FileUtils.mkdir_p(@math_dir)
    end

    def hash_formula(formula)
      Digest::MD5.hexdigest(formula.strip)
    end

    def render_formula_mml(formula, inline = false)
      hash = hash_formula(formula)
      filename = "#{hash}.mml"
      filepath = File.join(@math_dir, filename)

      return @cache[hash] if @cache.key?(hash)

      # Generate MathML using the Node script (KaTeX)
      script_path = File.join(@site.source, 'scripts', 'tex-render.js')
      args = [script_path, formula, @math_dir]
      args << '--inline' if inline

      stdout, stderr, status = Open3.capture3('node', *args)
      unless status.success?
        Jekyll.logger.error "MathRenderer:", "Failed to render formula: #{formula}"
        Jekyll.logger.error "MathRenderer:", stderr
        return formula
      end

      if File.exist?(filepath)
        content = File.read(filepath)
        # Cache the content for later inlining
        @cache[hash] = content
        return content
      else
        Jekyll.logger.error "MathRenderer:", "Expected output file not found: #{filepath}"
        return formula
      end
    end

    def escape_html(str)
      CGI.escapeHTML(str).gsub(/\s+/, ' ')
    end

    def process_content(content)
      # Process display math first (to avoid conflicts with inline math)
      content = content.gsub(DISPLAY_MATH_REGEX) do |match|
        formula = $1.strip
        mml = render_formula_mml(formula, false)
        "<div class=\"math-display page-width\">#{mml}</div>"
      end

      # Process inline math
      content = content.gsub(INLINE_MATH_REGEX) do |match|
        formula = $1.strip
        mml = render_formula_mml(formula, true)
        "<span class=\"math-inline\">#{mml}</span>"
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
