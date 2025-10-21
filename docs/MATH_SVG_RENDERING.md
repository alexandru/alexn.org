# Math Formula SVG Rendering

This document describes the changes made to convert the website from client-side MathJax rendering to server-side SVG generation.

## Changes Made

### 1. Added SVG Rendering Infrastructure

**File: `scripts/tex2svg.js`**
- Node.js script that uses `mathjax-node` to convert TeX formulas to SVG
- Generates hash-based filenames (MD5 of formula)
- Caches generated SVG files for reuse

**File: `_plugins/math_renderer.rb`**
- Jekyll plugin that processes markdown content before rendering
- Detects both inline (`$...$`) and display (`$$...$$`) math formulas
- Generates SVG files using the Node.js script
- Replaces math formulas with `<img>` tags pointing to the SVG files
- Includes the original TeX formula as alt text for accessibility

### 2. Removed Old MathJax JavaScript

**Removed:**
- `assets/js/load-mathjax.js` - Client-side MathJax loader
- MathJax preload link from `_includes/head.html`
- MathJax script tag from `_includes/scripts.html`

**Updated:**
- `package.json` - Removed `mathjax` dependency, added `mathjax-node` and `mathjax-node-cli`

### 3. Updated Content

**Modified Posts:**
- `_posts/2025-10-15-math-pill-1-sums.md`
- `_posts/2025-10-15-math-pill-2-square-roots.md`

Changed warning messages from:
> **WARN:** This article is using Mathjax to render math expressions. In case you're using a feed reader, you might want to load this article in the browser with JavaScript enabled.

To:
> **Note:** Math formulas in this article are rendered as SVG images for better portability and accessibility.

### 4. Configuration Changes

**Updated `.gitignore`:**
- Added `vendor/bundle/` to exclude bundler dependencies

## Benefits

1. **No JavaScript Required**: Math formulas now render without JavaScript, making them visible in feed readers and text-based browsers.

2. **Better Performance**: SVG files are generated once at build time and cached for reuse, resulting in faster page loads.

3. **Improved Accessibility**: Each SVG includes the original TeX formula as a title element and as alt text on the image tag.

4. **Portability**: Math formulas work everywhere, including in RSS feeds, email clients, and environments where JavaScript is disabled.

5. **SEO Friendly**: Search engines can index the alt text containing the mathematical formulas.

## Technical Details

### Formula Processing

The plugin processes formulas in this order:
1. Display math (`$$...$$`) - processed first to avoid conflicts
2. Inline math (`$...$`)

### SVG Generation

- Formula hash: MD5 of the TeX formula text
- Filename: `{hash}.svg`
- Location: `assets/math/{hash}.svg`
- Caching: Files are only generated once; subsequent builds reuse existing files

### Example Output

**Input:**
```markdown
$$
x^2 + y^2 = z^2
$$
```

**Output:**
```html
<img src="/assets/math/a132375055278e1c7b78b4a132c45ff3.svg" 
     alt="x^2 + y^2 = z^2" 
     class="math-display" />
```

**SVG Content:**
```xml
<svg xmlns:xlink="http://www.w3.org/1999/xlink" ... >
  <title id="MathJax-SVG-1-Title">x^2 + y^2 = z^2</title>
  ...
</svg>
```

## Build Process

1. Jekyll processes markdown files
2. For files with `mathjax: true` in frontmatter:
   - Plugin detects math formulas
   - Calls `scripts/tex2svg.js` to generate SVG files
   - Replaces formulas with `<img>` tags
3. SVG files are copied to `_site/assets/math/`

## Maintenance

- SVG files in `assets/math/` should be committed to the repository
- When formulas change, new SVG files will be generated automatically
- Old unused SVG files can be manually cleaned up if desired
