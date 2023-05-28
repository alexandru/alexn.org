---
title:  "Using the Best Tools in Programming: Not Really Doable"
date:   2009-02-01
last_modified_at: 2022-09-19 11:17:51 +03:00
image: /assets/media/articles/tools.png
---

<p class="intro">
  There's something that bothers me when it comes to starting a new project. You can't really use the best tool for a certain job, if that tool is not integrated with the rest of your platform. Let me explain.
</p>

At our startup we pride ourselves with our pragmatism. We are true polyglots :) capable of diving in any project, no matter the language it was written in. This also gives us the power to make educated choices about the technologies we're going to use for our own gigs.

Our programming language of choice is Perl, because of its flexibility and because usually there's no need to reinvent the wheel since you can find a CPAN module for almost anything.

But recently I began experimenting with data-mining techniques, flirting with various NLP libraries. You can find almost anything in CPAN's [AI:: namespace](https://search.cpan.org/search?query=AI%3A%3A&mode=module). But I also knew about [NLTK](https://www.nltk.org/), a Python collection of libraries with excellent documentation, and I also found [OpenNLP](https://opennlp.sourceforge.net/), [MontyLingua](https://web.media.mit.edu/~hugo/montylingua/), [ConceptNet](https://web.media.mit.edu/~hugo/conceptnet/), [link-grammar](https://www.abisource.com/projects/link-grammar/) and various [Ruby modules](https://www2.nict.go.jp/x/x161/members/mutiyama/software.html).

And all of a sudden I got cold feet. Java packages in OpenNLP may have the advantage of speed (just a guess and it doesn't matter for the purpose of this discussion). NLTK has pedigree and great documentation, not to mention that many books related to NLP, AI and data mining have Python samples (for example I own [Programming Collective Intelligence](https://oreilly.com/catalog/9780596529321/) and [AIMA](https://aima.cs.berkeley.edu/)). Usually the solution is straightforward: you test all the options, and choose the best one.

But what if you want to combine them?

Well, then you're shit out of luck. Surely you can do that with inter-process communication, but for that you'll have to write glue-code and pay the price for extra latency, bandwidth and memory ... parsing millions of documents, moving results between processes, it's not really practical. Perl does have [Inline::Java](https://search.cpan.org/dist/Inline-Java/Java.pod), but I would only use it in extreme situations.

That's why there's so much wheel reinvention around. Unless a module is written in C, for which any language has a FFI, almost nobody wants to use a Java module from Ruby, or a Python module from Perl. That's why there's [Lucene](https://lucene.apache.org/), and then there's [Lucene.NET](https://incubator.apache.org/lucene.net/), [CLucene](https://sourceforge.net/projects/clucene), [Ferret](https://www.oreillynet.com/onlamp/blog/2005/10/lucene_in_ruby_name_ferret_thi.html), [Zend_Search_Lucene](https://framework.zend.com/manual/en/zend.search.lucene.html#zend.search.lucene.introduction), [Plucene](https://search.cpan.org/~tmtm/Plucene-1.25/lib/Plucene.pm) and [Lucene4c](https://incubator.apache.org/lucene4c/).

What is really needed is a universal virtual machine with a flexible [MOP](https://en.wikipedia.org/wiki/Metaobject_Protocol), allowing seamless communication between languages. I'm happy there are a couple of efforts in this space, including [Parrot](https://www.parrot.org/), and the [DLR](https://en.wikipedia.org/wiki/Dynamic_Language_Runtime). Also, the biggest obstacles of alternative implementations are the modules written in C. Fortunately, JRuby/Rubinius have a brand new implementation-independent [FFI](https://blog.headius.com/2008/10/ffi-for-ruby-now-available.html), and [Ironclad](https://code.google.com/p/ironclad/) will allow IronPython users to use CPython extensions (number one on their list being numpy).

These developments make me happy :)