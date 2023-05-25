# coding: utf-8
#
# 1. Copy this file into the _plugins directory
# 2. Add dependencies via `npm install <lib> --save`
# 3. Link to them via `{% link /assets/js-managed/<lib>/<file.js> %}`
#

require 'fileutils'

# Installs required JavaScript libraries via `npm`
#
Jekyll::Hooks.register :site, :after_init do |site|
  cmd = "npm install"
  puts "$ #{cmd}"

  unless system(cmd)
    $stderr.puts("\nERROR — `#{cmd}` failed with status: #{$?}")
    exit 1
  end
end

module AlexN
  # Generator implementation that copies files from `./node_modules`
  # to `/_site/assets/js-managed`
  #
  # See: https://jekyllrb.com/docs/plugins/generators/
  #
  class ManagedJS < Jekyll::Generator
    def initialize(config = {})
      super(config)

      @node_modules_name = "node_modules"
      @dest_base = "/assets/js-managed"

      @ignored_extensions = /\.(md)$/i
      @ignored_paths = /(
        package[^.]*\.json$ |
        \btests?\b |
        \bmathjax[\/\\]unpacked\b
      )/ix
    end

    def generate(site)
      node_modules_path = File.join(site.source, @node_modules_name)

      unless File.directory? node_modules_path
        $stderr.puts "ERROR: ./#{@node_modules_name}/ directory does not exist"
        exit 1
      end

      dest_regexp = /#{Regexp.escape(File.absolute_path(node_modules_path))}[\/\\]/

      start = Time.now
      Jekyll.logger.info("         ManagedJS: Copying ./#{@node_modules_name} to #{@dest_base}")
      
      Dir.glob("#{node_modules_path}/**/*.*") do |p|
        # ignore directories
        next unless File.file? p
        # ignore specific extensions
        next if p.match? @ignored_extensions
        # ignore specific paths
        next if p.match? @ignored_paths

        path_rel = File.absolute_path(p).sub dest_regexp, ""

        file = AlexN::ManagedStaticFile.new(
          site,
          site.source,
          @node_modules_name,
          path_rel,
          @dest_base)

        site.static_files << file
      end

      Jekyll.logger.info("                    ...done in #{Time.now - start} secs.")
    end
  end

  # Wraps the `StaticFile` object, needed for calculating the destination
  # file path (for instructing Jekyll where to copy the file).
  #
  # See:
  #  - https://www.rubydoc.info/github/jekyll/jekyll/Jekyll/StaticFile
  #  - https://github.com/jekyll/jekyll/blob/v3.7.1/lib/jekyll/static_file.rb
  #
  class ManagedStaticFile < Jekyll::StaticFile
    def initialize(site, site_base, file_base, file_relative_path, dest_base)
      super(site, site_base, File.join(file_base, File.dirname(file_relative_path)), File.basename(file_relative_path))
      @my_dest_base = dest_base
      @my_file_relative_path = file_relative_path
      # override!
      @relative_path = File.join(dest_base, file_relative_path)
    end

    # Overrides base method
    def destination(dest)
      File.join(dest, @my_dest_base, @my_file_relative_path)
    end

    # Overrides base method
    def destination_rel_dir
      File.dirname(@relative_path)
    end
  end
end
