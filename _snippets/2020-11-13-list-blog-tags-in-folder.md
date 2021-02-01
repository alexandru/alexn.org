---
title: "List static blog tags in folder (Jekyll, etc)"
date: 2020-11-13 15:59:43+0200
tags:
  - Blogging
  - Jekyll
  - Ruby
image: /assets/media/snippets/script-list-tags.png
---

I maintain a Jekyll blog, with tagged articles (tags specified in the Markdown front-matter), but maintaining tags isn't easy, because I often forget what tags I used. E.g. is it `Functional`, or `FP`? I can never remember.

Here's a simple script that traverses all the files in a directory, parsing their YAML front-matter, gathers all the tags, then displays them sorted by popularity:

```ruby
#!/usr/bin/env ruby

require 'optparse'
require "json"
require "yaml"

options = {}
OptionParser.new do |opt|
  opt.on('--folder PATH') { |o| options[:path] = File.expand_path(o) }
end.parse!

if !options[:path] && ARGV[0] && File.directory?(ARGV[0])
  options[:path] = File.expand_path(ARGV[0])
end
raise OptionParser::MissingArgument.new("--folder") if options[:path].nil?

filters = [
  File.join(options[:path], "*.md"),
  File.join(options[:path], "*.markdown"),
  File.join(options[:path], "*.html"),
  File.join(options[:path], "*.htm"),
]

all_tags = {}
filters.each do |filter|
  Dir[filter].each do |path|
    contents = File.read(path)
    if contents =~ /\A---\s*\r?\n(.*?)^---/m
      yaml_str = ($1).strip
      yaml = YAML.load(yaml_str)
      tags = yaml['tags'] || []
      tags.each do |tag|
        all_tags[tag] ||= 0
        all_tags[tag] += 1
      end
    end
  end
end

all_tags.to_a.sort_by{|x| -x[1]}.each do |tag|
  printf("%20s %3d\n", tag[0], tag[1])
end
```

E.g. invoking it on my current `_snippets` folder reveals:

```sh
$ list-tags _snippets
               Scala  15
         Cats Effect   7
                Akka   4
    Reactive Streams   4
               Async   3
              Python   2
                 sbt   2
          TypeScript   2
                 CLI   2
                  FP   2
                Bash   1
                Ruby   1
              Jekyll   1
             Testing   1
               Monix   1
                 Fun   1
             Haskell   1
                 JVM   1
          JavaScript   1
```