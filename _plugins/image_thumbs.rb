require 'mini_magick'

module Jekyll
  module JekyllMinimagick

    class GeneratedImageFile < Jekyll::StaticFile
      # Initialize a new GeneratedImage.
      #   +site+ is the Site
      #   +base+ is the String path to the <source>
      #   +dir+ is the String path between <source> and the file
      #   +name+ is the String filename of the file
      #   +preset+ is the Preset hash from the config.
      #
      # Returns <GeneratedImageFile>
      def initialize(site, base, dir, name, source_dir, preset)
        super(site, base, dir, name)
        @src_dir = File.expand_path(source_dir).sub(File.expand_path(site.source) + "/", "")
        @dst_dir = preset.delete('destination')
        @commands = preset
      end

      # Obtains source file path by substituting the preset's source directory
      # for the destination directory.
      #
      # Returns source file path.
      def path
        File.join(@base, @dir.sub(@dst_dir, @src_dir), @name)
      end

      # Use MiniMagick to create a derivative image at the destination
      # specified (if the original is modified).
      #   +dest+ is the String path to the destination dir
      #
      # Returns false if the file was not modified since last time (no-op).
      def write(dest)
        dest_path = destination(dest)
        return false if File.exist? dest_path and !modified?        
        Jekyll.logger.info("                    #{dest_path}")
        
        self.class.mtimes[path] = mtime

        FileUtils.mkdir_p(File.dirname(dest_path))
        image = ::MiniMagick::Image.open(path)
        @commands.each_pair do |command, arg|
          if !!arg == arg && arg
            image.send command
          elsif arg.kind_of?(Array)
            arg.each do |value|
              image.send command, value
            end
          else
            image.send command, arg
          end
        end
        image.write dest_path
        true
      end
    end

    class MiniMagickGenerator < Generator
      safe true

      # Find all image files in the source directories of the presets specified
      # in the site config.  Add a GeneratedImageFile to the static_files stack
      # for later processing.
      def generate(site)        
        return unless site.config['thumbnails']

        all_images = site.posts.docs.map {|p| p.data['image']}.filter{|i| !!i}.map{|p|File.join(site.source, p)}

        site.config['thumbnails'].each_pair do |name, preset|
          Jekyll.logger.info("        Thumbnails: generating #{name} preset")
          start = Time.now

          all_images.each do |source|
            file = GeneratedImageFile.new(site, site.source, preset['destination'], File.basename(source), File.dirname(source), preset.clone)
            site.static_files << file
            file.write(site.dest)
          end
          
          Jekyll.logger.info("                    ...done in #{Time.now - start} secs.")
        end
      end
    end
  end
end
