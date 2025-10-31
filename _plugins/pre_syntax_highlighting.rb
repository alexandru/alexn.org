module PreSyntaxHighlighting
  class Generator < Jekyll::Generator
    def generate(site)
      site.pages.each { |page| process(page) }
      site.posts.docs.each { |post| process(post) }
      site.collections.each { |_, collection| collection.docs.each { |doc| process(doc) } }
    end

    private

    def process(doc)
      return unless doc.content.include?("```")
      
      # Convert ```scala reset or ```scala ignore to ```scala
      doc.content = doc.content.gsub(/^```(\w+)\s+\w+\s*$/, '```\1')
    end
  end
end