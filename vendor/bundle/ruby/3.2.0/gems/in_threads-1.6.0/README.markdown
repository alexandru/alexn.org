[![Gem Version](https://img.shields.io/gem/v/in_threads?logo=rubygems)](https://rubygems.org/gems/in_threads)
[![Build Status](https://img.shields.io/github/workflow/status/toy/in_threads/check/master?logo=github)](https://github.com/toy/in_threads/actions/workflows/check.yml)
[![Code Climate](https://img.shields.io/codeclimate/maintainability/toy/in_threads?logo=codeclimate)](https://codeclimate.com/github/toy/in_threads)
[![Depfu](https://img.shields.io/depfu/toy/in_threads)](https://depfu.com/github/toy/in_threads)
[![Inch CI](https://inch-ci.org/github/toy/in_threads.svg?branch=master)](https://inch-ci.org/github/toy/in_threads)

# in_threads

Run all possible enumerable methods in concurrent/parallel threads.

```ruby
urls.in_threads(20).map do |url|
  HTTP.get(url)
end
```

## Installation

Add the gem to your Gemfile...

```ruby
gem 'in_threads'
```

...and install it with [Bundler](http://bundler.io).

```sh
bundle install
```

Or install globally:

```sh
gem install in_threads
```

## Usage

Let's say you have a list of web pages to download.

```ruby
urls = [
  "https://google.com",
  "https://en.wikipedia.org/wiki/Ruby",
  "https://news.ycombinator.com",
  "https://github.com/trending"
]
```

You can easily download each web page one after the other.

```ruby
urls.each do |url|
  HTTP.get(url)
end
```

However, this is slow, especially for a large number of web pages. Instead,
download the web pages in parallel with `in_threads`.

```ruby
require 'in_threads'

urls.in_threads.each do |url|
  HTTP.get(url)
end
```

By calling `in_threads`, the each web page is downloaded in its own thread,
reducing the time by almost 4x.

By default, no more than 10 threads run at any one time. However, this can be
easily overriden.

```ruby
# Read all XML files in a directory
Dir['*.xml'].in_threads(100).each do |file|
  File.read(file)
end
```

Predicate methods (methods that return `true` or `false` for each object in a
collection) are particularly well suited for use with `in_threads`.

```ruby
# Are all URLs valid?
urls.in_threads.all? { |url| HTTP.get(url).status == 200 }

# Are any URLs invalid?
urls.in_threads.any? { |url| HTTP.get(url).status == 404 }
```

### Compatibility

All methods of `Enumerable` with a block can be used if block calls are evaluated independently, so following will

`all?`, `any?`, `collect_concat`, `collect`, `count`, `cycle`, `detect`, `drop_while`, `each_cons`, `each_entry`,
`each_slice`, `each_with_index`, `each_with_object`, `each`, `enum_cons`, `enum_slice`, `enum_with_index`,
`filter_map`, `filter`, `find_all`, `find_index`, `find`, `flat_map`, `group_by`, `map`, `max_by`, `min_by`,
`minmax_by`, `none?`, `one?`, `partition`, `reject`, `reverse_each`, `select`, `sort_by`, `sum`, `take_while`, `to_h`,
`to_set`, `uniq`, `zip`.

Following either don't accept block (like `first`), depend on previous block evaluation (like `inject`) or return an enumerator (like `chunk`), so will simply act as if `in_threads` wasn't used:

`chain`, `chunk_while`, `chunk`, `compact`, `drop`, `entries`, `first`, `include?`, `inject`, `lazy`, `max`, `member?`,
`minmax`, `min`, `reduce`, `slice_after`, `slice_before`, `slice_when`, `sort`, `take`, `tally`, `to_a`.

### Break and exceptions

Exceptions are caught and re-thrown after allowing blocks that are still running to finish.

**IMPORTANT**: only the first encountered exception is propagated, so it is recommended to handle exceptions in the block.

`break` is handled in ruby >= 1.9 and should be handled in jruby [9.1 after 9.1.9.0](https://github.com/jruby/jruby/issues/4697) and [9.2 and 9.3 after #7009](https://github.com/jruby/jruby/issues/7009). Handling is done in special way: as blocks are run outside of original context, calls to `break` cause `LocalJumpError` which is caught and its result is returned.

## Copyright

Copyright (c) 2009-2022 Ivan Kuchin. See LICENSE.txt for details.
