#
# Source: <https://satyanash.net/software/2021/05/29/better-way-to-inline-sass-jekyll.html>
#
# file: _plugins/inline_sass.rb
class InlineSassGenerator < Jekyll::Generator
  SASS_FILE = './_sass/all.scss'

  def generate(site)
    site.find_converter_instance(Jekyll::Converters::Scss)
        .convert(File.read(SASS_FILE))
        .tap { |styles| site.data['styles'] = styles }
  end
end
