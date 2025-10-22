---
title: "Update on Math Formulas via Copilot"
mathjax: true
image: /assets/media/articles/2025-math-github-copilot.png
image_hide_in_post: true
---

<p class="intro">
Or how I'm using GitHub's Copilot in Agent mode for yak shaving, evolving my Jekyll-powered website for rendering mathematical formulas by SVG images, instead of heavy JavaScript.
</p>

This blog uses [Mathjax](https://github.com/mathjax/MathJax) for rendering math formulas, see my posts on [Math](/blog/tag/math/). But Mathjax is a JavaScript library, and it was running client-side, in the browser. And I tend to avoid JavaScript for this particular website.

Given that I intend to write more math formulas, it bothered me that the dependence on JavaScript is hurting this blog's [RSS feed](/feeds/blog.xml){:target="_blank"}, as RSS feed items can't have JS in them. Also, the page rendering is slow and dirty, hurting the user experience due to that brief moment between the static HTML being loaded and MathJax doing its job, during which one can see the raw TeX syntax, and the page layout shifts to accommodate the JS-powered rendering.

I've now switched the implementation to one that uses Mathjax on the server-side, when the website is built, translating those formulas to SVG images. Here's how:

- [PR, started by Copilot](https://github.com/alexandru/alexn.org/pull/83)
- [Commit fixing RSS and dark-mode](https://github.com/alexandru/alexn.org/commit/ebe455f2c5e450227e744412f5f66aedaa584f7d), because life can't be simple.

Here's a sample. You can inspect it or "view source" for confirmation:

$$
F = G\frac{m1 \cdot m2}{r^2}
$$

As a side-note, this is one of those times when I appreciate having full control over the implementation of my blog, instead of using WordPress or other, more evolved off-the-shelf solutions (I'm thinking here of [my previous article on outsourced voices](./2025-10-13-outsourced-voices-outsourced-minds.md)).

I used GitHub's Copilot, [running as an Agent on GitHub](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-coding-agent), to start the PR and take care of the most difficult parts. It worked, but it needed supervision. Therefore, this is also a tale of how I used Copilot to modify my blog's implementation.

For instructing Copilot, I started with this prompt:

> This website currently uses Mathjax for rendering math formulas. However, I'd like those math formulas to be more portable, i.e., to not require JavaScript for rendering.
>
> Modify the website such that math formulas get rendered to SVG images, using the original TeX formula as "alt" text for the visually impaired.
> 
> Suggestions:
> 
> - Use mathjax-node for the rendering to SVG files (placed in `/assets/math` at build time).
> - Use the formula's hashcode as the SVG file name.
> - Reuse already generated files for repeated formulas.
> - Introduce a Jekyll plugin that searches and replaces math/TeX code to image tags pointing to these SVG files, also generating the files when needed.

Upon inspecting the result, which wasn't bad, I then followed up with a change request:

> Unfortunately, I now saw that `mathjax-node` is an old package.
>
> Drop it from the project and use the latest stable version of Mathjax and whatever it is needed to make it work.

After reviewing the generated code, I noticed Copilot didn't do the right thing. It broke the command meant for development, `jekyll serve`. It certainly helped that I know how to do the job well:

> There is a problem with this approach. These SVG files shouldn't be generated directly in the project's sources, for one, because I don't want them to be added to the repository, but also, because it breaks `jekyll serve`.
> 
> These files should be generated using Jekyll's mechanism, by appending to `site.static_files` a `Jekyll::StaticFile` instance. There is already an example in `managed_js.rb`.
>
> The result of this should be that `/assets/math` should be available only in the `_site` directory after a jekyll build and the images should be served via `jekyll serve` as well (so without an explicit `_site` directory being built).
>
> Also, remove the current `assets/math` directory from this PR.

Plenty of micro-management here, telling it precisely what to do. And then the result was buggy: 

- I discovered that it doesn't escape the SVG's `title` properly, and followed up with a fix myself.
- The `width` and `height` attributes were not calculated correctly by my setup, due to Mathjax preferring `ex` as the unit type, referring to the width and height of an `x` character of a font (weird). I did plenty of CSS tweaks that I'm not sure Copilot could've done.
- The RSS feed wouldn't work in dark mode, because the SVGs are black text on transparent background, and I couldn't find a way to add CSS styling to the RSS feeds. Here, Copilot was completely disappointing. My final solution was to generate "transparent background" versions for the website and "light background" versions for the RSS feed.

I used the "agent mode" in Visual Studio Code as well. The results when using GPT-4.1 are very poor, which is a pity, as this is the model with an unlimited number of requests on GitHub Copilot's Pro plan. Claude Sonnet fared much better (at coding tasks in agent mode, but it's poor at others, such as high-school math).

At the time of writing, I now have another attempt at using Copilot Agent for optimizations: [Optimize Jekyll build time for Mathjax and image processing](https://github.com/alexandru/alexn.org/pull/84); because the build times have gone up and that's bad, too.

It certainly has potential.
