# Jekyll to Laika Migration Plan (Comprehensive)

Goal: migrate `alexn.org` from Jekyll (Ruby + Liquid + custom plugins) to Laika (Scala), while preserving behavior, URLs, feed compatibility, and design.

Reference material:
- Laika docs ebook: `./plans/laika-1.x-library.epub`
- Inspiration repo: <https://github.com/typelevel/typelevel.github.com/> (ideas only, no blind copying)

---

## 1) Migration Principles

- [ ] **No broken URLs**: keep existing permalinks and redirects stable.
- [ ] **No regressions in published output**: preserve page structure, metadata, feeds, and UX.
- [ ] **Incremental cutover**: run Jekyll and Laika builds in parallel before switching production.
- [ ] **Early CI coverage for migration PRs**: update per-PR GitHub Actions first so every migration PR exercises `build.scala`, even before feature parity.
- [ ] **Preserve author workflow**: replace helper scripts (`scripts/add-blog`, `scripts/add-wiki`, etc.) with equivalent Scala tooling or keep wrappers.
- [ ] **Make behavior explicit**: every Jekyll plugin/filter/custom include gets mapped to a named Laika extension or build step.
- [ ] **Toolchain lock**: use Scala 3 and compile with `--no-indent --rewrite` options.

---

## 2) Current Repository Feature Inventory (What must survive)

### 2.1 Content types and source layout

- [ ] Blog posts from `_posts/` with date-based URLs.
- [ ] Wiki pages from `_wiki/` with dedicated layout and index.
- [ ] Static/standalone pages: `index.html`, `about.html`, `subscribe.html`, `404.html`, `docs/*.md`, `assets/html/*`.
- [ ] Feeds from `feeds/*.xml` with custom include fragments.

### 2.2 URL and routing conventions

- [ ] Blog permalinks: `/blog/:year/:month/:day/:title/`.
- [ ] Wiki permalinks: `/wiki/:title/`.
- [ ] Docs/assets HTML clean URLs (`/:path/:basename/` behavior from `_config.yml` defaults).
- [ ] Tag pages under `/blog/tag/:tag/`.
- [ ] Existing `redirect_from` behavior and generated redirect artifacts (`_redirects`, `nginx.conf` inclusion block).

### 2.3 Page composition and templates

- [ ] Layout system equivalent to `_layouts/*` (default, page, post, wiki, pagination, tag pages).
- [ ] Include/component equivalents for `_includes/*` (head, scripts, header/footer, comments, TOC, feed item templates, YouTube block).
- [ ] CSS pipeline and inlining strategy from `_sass/*` + `inline_sass.rb` (currently injects compiled CSS into `<style>`).

### 2.4 Data and front matter semantics

Front matter keys currently in active use include (not exhaustive):

- [ ] `title`, `description`, `date`, `last_modified_at`
- [ ] `tags`, `image`, `image_caption`, `image_hide_in_post`
- [ ] `youtube`, `mathjax`, `generate_toc`
- [ ] `redirect_from`, `feed_guid`, `social_description`, `secret`, `is_noise`
- [ ] layout control flags: `has_subscribe`, `has_comments`, `has_contributions`, `disable_meta`, `disable_title`, `nav_id`, etc.

### 2.5 Jekyll/plugin behavior to replicate

- [ ] `pre_syntax_highlighting.rb`: normalize fenced code headers like ```` ```scala reset ```` -> ```` ```scala ````.
- [ ] `math_renderer.rb`: server-side TeX -> SVG generation via Node (`scripts/tex2svg.js`), cached in `.jekyll-cache/math-svg`, dual outputs (`transparent/`, `white/`), injected `<img>` HTML.
- [ ] `image_filters.rb`: auto-insert image width/height + decoding attr, including special handling for math SVG dimensions.
- [ ] `html_filters.rb`:
  - [ ] custom date formatting
  - [ ] smart XML escaping
  - [ ] related-post scoring by tag overlap
  - [ ] RSS content normalization/rewriting (absolute URLs, image rewriting to white math SVG variant in feeds, remove `.hide-in-feed` blocks)
  - [ ] campaign query parameter handling
  - [ ] social text length validation
- [ ] `post_render.rb`: post-build generation of redirect rules in `_site/_redirects` and `_site/nginx.conf`.
- [ ] `video_links.rb`: YouTube URL helpers.
- [ ] `image_thumbs.rb`: thumbnail generation pipeline (currently disabled in config, but code exists and should be intentionally handled).
- [ ] `inline_sass.rb`: compile Sass and inline output.
- [ ] `managed_js.rb`: `npm install` hook + copy selected `node_modules` files to `/assets/js-managed`.

### 2.6 External integrations and output behaviors

- [ ] Highlight.js module loading from managed JS assets.
- [ ] Isso comments embed + no-JS fallback copy.
- [ ] Tracking pixel logic in page scripts and feeds.
- [ ] RSS feeds: `blog.xml`, `wiki.xml`, `newsletter.xml`, `reddit.xml`, `social.xml`.
- [ ] SEO/meta tags + social cards from `head.html`.
- [ ] `robots.txt`, `manifest.webmanifest`, `sitemap.xml` equivalent.

---

## 3) Recommended Target Architecture (Laika + Scala)

### 3.1 Build topology

- [ ] Use **Scala-CLI** as the build runner (`scala-cli run ...`), not `sbt`.
- [ ] Keep a thin command entrypoint script at repo root (`build.scala`) and place implementation code under top-level `src/**`.
- [ ] Define Laika input trees for posts, wiki, docs/pages, and static assets.
- [ ] Use separate output roots during migration to avoid artifact collision:
  - [ ] Jekyll output: `_site-jekyll/`
  - [ ] Laika output: `_site-laika/`
  - [ ] Deployment handoff path (`_site/`) is produced only by the active generator in release jobs.

### 3.2 Laika extension strategy

- [ ] Implement a custom Laika extension bundle for:
  - [ ] directives/templates for Jekyll-compatible behavior in the dual-run phase
  - [ ] later-stage Liquid-to-HTML canonicalization pipeline
  - [ ] rewrite rules/AST transforms for front matter semantics
  - [ ] pre-parse normalization (fence cleanup)
  - [ ] post-render hooks for redirects and feed post-processing

### 3.3 Templating/theming

- [ ] Port layouts/includes to Laika templates while preserving generated HTML structure (as much as practical).
- [ ] Preserve CSS as-is initially (compile same Sass and inject/link with parity mode).
- [ ] Preserve JS paths and query-busting strategy while migration is in flight.

### 3.4 Non-Laika helper tasks

- [ ] Add Scala-CLI-invoked task wrappers for Node-based steps (`npm ci`, MathJax SVG generation, managed asset copy).
- [ ] Add a verification task that compares selected Jekyll and Laika output files.

---

## 4) Workstreams and Checklists

## W0 - Baseline and Safety Net

- [ ] Freeze baseline outputs from current Jekyll build (`_site-jekyll/`) for comparison snapshots.
- [ ] Define golden-page comparison set (home, blog index, wiki index, representative post types, feed XMLs, 404, about, subscribe).
- [ ] Add URL crawl snapshot (all existing output paths + redirect map).
- [ ] Add feed validation script (XML parse + required fields checks).

Deliverable: reproducible baseline artifact and acceptance script.

## W0.5 - PR Workflow Bootstrap (First Step)

- [ ] Update `.github/workflows/build.yml` immediately so `pull_request` runs a Scala/Laika build validation job.
- [ ] Wire a minimal command that must execute on PRs (even if functionality is still a scaffold), e.g. `scala-cli run build.scala -- build --out _site-laika`.
- [ ] Keep existing Jekyll checks intact while migration is in progress.
- [ ] Keep this strictly validation-only for PRs: do not deploy Laika output from this workflow stage.

Deliverable: all migration PRs run a Scala/Laika build job in CI from day one.

## W1 - Bootstrap Laika Build

- [ ] Initialize Scala-CLI + Laika project and wire CLI tasks (e.g. `scala-cli run build.scala -- build --out _site-laika`).
- [ ] Ensure code organization from day one (`src/**`), avoiding a monolithic root script.
- [ ] Configure Scala version to Scala 3 and set compiler options to `--no-indent --rewrite` in Scala-CLI directives.
- [ ] Configure site-wide metadata (`title`, `description`, author links, domain/url/baseurl semantics).
- [ ] Ensure static file passthrough works (`assets`, `.well-known`, `CNAME`, `robots.txt`, etc.).
- [ ] Add dev-mode command for local preview (e.g. `scala-cli run build.scala -- serve --port 4000`).

Deliverable: minimal Laika build producing homepage shell and static assets.

## W2 - Content Ingestion and Front Matter Compatibility

- [ ] Map `_posts/` to blog document tree with correct dates and URL schema.
- [ ] Map `_wiki/` to wiki document tree with `/wiki/:title/` URLs.
- [ ] Support existing front matter fields used by templates/logic.
- [ ] Implement migration-safe parser behavior for date formats currently present in repo.
- [ ] Preserve markdown rendering characteristics needed by existing content.

Deliverable: documents render with correct URLs and metadata.

## W3 - Template and Layout Port

- [ ] Port `default`, `page`, `post`, `wiki` layout behavior.
- [ ] Port reusable include-like components:
  - [ ] `head`
  - [ ] `header`
  - [ ] `footer`
  - [ ] `scripts`
  - [ ] `post-excerpt`
  - [ ] `comments`
  - [ ] `youtube`
  - [ ] contribution/subscription blocks
- [ ] Reproduce TOC and anchor-heading behavior.
- [ ] Keep schema.org metadata and social card output parity.

Deliverable: visual and semantic parity for core page types.

## W4 - Taxonomy, Indexes, and Pagination

- [ ] Implement blog index pagination equivalent to `jekyll-paginate-v2` behavior.
- [ ] Implement wiki index sorted by title.
- [ ] Implement tag pages with pagination under `/blog/tag/:tag/`.
- [ ] Preserve tag URL normalization (downcase + URI escape).
- [ ] Implement related articles scoring logic (tag overlap + date ordering fallback).

Deliverable: navigation flows (home -> post/wiki -> tag/archive) fully working.

## W5 - Feeds (High Priority)

- [ ] Rebuild all current feeds with parity intent:
  - [ ] `feeds/blog.xml`
  - [ ] `feeds/wiki.xml`
  - [ ] `feeds/newsletter.xml`
  - [ ] `feeds/reddit.xml`
  - [ ] `feeds/social.xml`
- [ ] Port feed item template logic from `_includes/feed-item-blog.xml` and `_includes/feed-item-wiki.xml`.
- [ ] Preserve item filtering rules (`secret`, `is_noise` etc.).
- [ ] Preserve campaign/tracking parameter behavior in feed links.
- [ ] Preserve math image rewriting to white SVG variant for feeds.
- [ ] Treat feed parity sign-off as blocked until W6 math asset prerequisites are complete.
- [ ] Validate social-description length guard logic.

Deliverable: feed XML validated + diff-reviewed against baseline.

## W6 - Math and Media Processing

- [ ] Complete W6 before final W5 feed parity checks.
- [ ] Port `mathjax: true` content transformation using existing `scripts/tex2svg.js`.
- [ ] Keep deterministic hash-based caching behavior.
- [ ] Ensure generated SVG assets are copied to `/assets/math/{transparent,white}/`.
- [ ] Preserve rendered HTML structure/classes for math blocks/inline formulas.
- [ ] Ensure RSS uses white-background variant while site uses transparent variant.

Deliverable: math-heavy posts render identically enough in browser and feeds.

## W7 - Image Processing and HTML Post-Processing

- [ ] Auto-insert width/height on images where currently expected.
- [ ] Preserve decoding/loading attribute behavior where relevant.
- [ ] Preserve absolute URL conversion for feed content.
- [ ] Preserve `.hide-in-feed` content stripping.

Deliverable: no layout shift regressions and clean feed HTML.

## W8 - Redirects and Web-Server Artifacts

- [ ] Implement `redirect_from` handling and generation of redirect map.
- [ ] Generate Netlify-style `_redirects` with automated section replacement.
- [ ] Generate `nginx.conf` include section with same rewrite rules.
- [ ] Preserve manual redirect rules already in root `_redirects` and `nginx.conf`.

Deliverable: redirect behavior parity in local/staging tests.

## W9 - Node/JS Managed Assets

- [ ] Recreate managed JS copy behavior currently from `managed_js.rb`.
- [ ] Install/copy `@highlightjs/cdn-assets` and `jquery` into output paths expected by templates.
- [ ] Keep highlight initialization script behavior.
- [ ] Decide whether to keep raw copy model or migrate to bundler later (post-parity refactor).

Deliverable: no broken script imports after cutover.

## W10 - CI/CD and Deployment

- [ ] Expand the early PR workflow bootstrap (W0.5) into full Scala/Laika CI/CD ownership in `.github/workflows/*`.
- [ ] Preserve Node and math cache strategy (or improve with equivalent cache keys).
- [ ] Keep deployment target behavior stable (current gh-pages / Cloudflare pipeline expectations).
- [ ] Remove Ruby dependencies only after successful parallel phase.

Deliverable: green CI for PRs + deploy on main.

## W11 - Parallel Run, Diffing, and Cutover

- [ ] Run both generators in CI for a period and publish comparison reports using isolated outputs (`_site-jekyll/` vs `_site-laika/`).
- [ ] Classify diffs into: acceptable, bug, intentional improvement.
- [ ] Fix blocking diffs (URLs, feeds, metadata, redirects, math, pagination).
- [ ] Cut over production build to Laika once acceptance gates pass.
- [ ] Keep rollback path for one release cycle.

Deliverable: production cutover with rollback confidence.

## W12 - Source Canonicalization (Post-Cutover / Optional but Recommended)

- [ ] Introduce deterministic codemods for Liquid -> HTML marker transformations in source content.
- [ ] Convert high-frequency constructs first (`{% include youtube.html %}`, `{% link %}`, `{% post_url %}`).
- [ ] Keep codemods idempotent and reversible.
- [ ] Re-run full parity suite after each codemod batch.
- [ ] Remove now-obsolete compatibility shim logic only after codemod completion.

Deliverable: source content no longer depends on legacy Liquid syntax for core features.

---

## 5) Jekyll -> Laika Mapping Matrix

| Current mechanism | Used for | Laika/Scala replacement |
|---|---|---|
| Liquid layouts/includes | Page rendering | Laika templates + reusable partial templates/directives |
| `jekyll-paginate-v2` | Blog/tag pagination | Custom pagination logic in Laika templates/extension |
| `jekyll-titles-from-headings` | Implicit titles | Laika front matter/title fallback logic |
| `jekyll-relative-links` | Internal link normalization | Laika link rewriting + validation phase |
| `jekyll-redirect-from` | Redirect maps | Scala redirect collector + output generators (`_redirects`, `nginx.conf`) |
| `jekyll-sitemap` | Sitemap | Laika sitemap generation (custom if needed) |
| `pre_syntax_highlighting.rb` | Fence normalization | Preprocessing transform over Markdown sources |
| `math_renderer.rb` + `tex2svg.js` | Math SVG generation | Scala task invoking Node script + content rewrite rule |
| `image_filters.rb` | Width/height injection | HTML post-processor over rendered output |
| `html_filters.rb` | Feed processing/utilities | Scala utility module + feed rendering helpers |
| `inline_sass.rb` | Inline CSS | Scala-CLI task + Sass compilation + template injection |
| `managed_js.rb` | npm install + copy assets | Scala-CLI orchestrated npm task + static asset copy |

---

## 6) Acceptance Criteria (Definition of Done)

- [ ] All canonical URLs from current site resolve with same content intent.
- [ ] Existing redirects still resolve correctly.
- [ ] Blog, wiki, tag pages, pagination, and 404 behave correctly.
- [ ] Feeds parse cleanly and preserve item ordering, categories/tags, and key fields.
- [ ] Math posts render with server-side SVGs and feed-compatible variant.
- [ ] Core SEO/social metadata parity achieved (title, canonical, OG/Twitter essentials).
- [ ] CSS/JS asset loading has no broken links.
- [ ] CI and deploy pipeline stable for at least N consecutive main-branch deploys.

### 6.1 Comparator rules (machine-decidable parity)

- [ ] URL inventory parity: exact path-set match after sorting; no missing or extra canonical URLs.
- [ ] Redirect parity: rule-level semantic match (source pattern, status/type, destination).
- [ ] Feed parity: XML parsed and compared on semantic fields (`title`, `link`, `guid`, `pubDate`, categories, author, enclosure/media where applicable) ignoring non-semantic whitespace.
- [ ] HTML parity: normalized DOM comparison for selected golden pages with explicit ignore list:
  - [ ] ignore whitespace-only text node differences
  - [ ] ignore attribute ordering differences
  - [ ] ignore known generated nonces/timestamps/build IDs
  - [ ] do not ignore URL, metadata, heading IDs, or content text

---

## 7) Recommended Execution Order

1. W0.5 PR workflow bootstrap (first implementation step)
2. W0 Baseline + W1 Bootstrap
3. W2 Content ingestion
4. W3 Templates + W4 Taxonomy/pagination
5. W5 Feeds
6. W6 Math/media prerequisites
7. W5 Feeds final parity pass
8. W7 Media post-processing
9. W8 Redirect artifacts
10. W9 Node asset pipeline
11. W10 CI/CD full cutover
12. W11 Parallel run + cutover
13. W12 Source canonicalization (deferred)

---

## 8) Risks and Mitigations

- [ ] **Risk: hidden Liquid edge cases in legacy posts**  
      Mitigation: use a phased strategy: keep source-compatible behavior during dual-run, then perform explicit Liquid-to-HTML canonicalization after parity gates pass.
- [ ] **Risk: feed regressions break downstream automations**  
      Mitigation: snapshot and validate feed output with strict XML and semantic checks before cutover.
- [ ] **Risk: URL drift (especially tag/pagination pages)**  
      Mitigation: generate URL inventories from both builds and diff in CI.
- [ ] **Risk: math rendering differences**  
      Mitigation: lock MathJax versions and compare rendered SVG hashes/visual output for representative formulas.
- [ ] **Risk: migration scope creep**  
      Mitigation: parity-first policy; postpone redesign/refactors until after stable cutover.

---

## 9) Post-Cutover Cleanup (After Stability Window)

- [ ] Remove Ruby/Jekyll dependencies (`Gemfile`, plugins) once no longer needed.
- [ ] Retire Jekyll-specific scripts and docs.
- [ ] Keep or modernize Node asset strategy (optional bundler migration).
- [ ] Document the new author workflow and extension points.

---

## Notes from Repository Analysis

- The migration is not just a templating port; a lot of behavior currently lives in custom Ruby plugins and feed filters.
- Feeds, redirects, and math rendering are high-risk/high-value areas and should be treated as first-class workstreams, not side tasks.
- A parity-first dual-build phase is strongly recommended before flipping production.

---

## 10) Concrete Findings (Scope/Complexity Snapshot)

These are concrete facts from this repository that materially affect migration strategy.

- [ ] Content volume to migrate:
  - [ ] `_posts/`: 156 files (including 2 legacy `.html` posts)
  - [ ] `_wiki/`: 52 markdown docs
  - [ ] `feeds/`: 5 XML outputs
- [ ] Liquid usage inside content is non-trivial:
  - [ ] `{% link ... %}` usages: 100+
  - [ ] `{% include ... %}` usages in content/pages: 20+
  - [ ] `{% include youtube.html ... %}` usages: 17
  - [ ] `{% post_url ... %}` exists (legacy posts)
  - [ ] `{% raw %}...{% endraw %}` exists (used to escape `{{ ... }}` samples)
- [ ] Existing front matter is YAML (`---`) while Laika's native config header is HOCON (`{% ... %}`) by default.
- [ ] Current social feed template contains a branch for `post.collection == 'links'`, but there is no local `feed-item-link.xml`; preserve/clean this intentionally.

Implication: this is both a generator migration and a syntax/runtime compatibility migration.

---

## 11) Architecture Decisions to Lock Early

These decisions should be made before large-scale coding because they impact all workstreams.

### D1 - Content compatibility strategy

- [ ] **Phase 1 (dual-run, parity-first):** keep source content unchanged so Jekyll can still build the site for A/B validation.
  - [ ] Keep YAML front matter and existing Liquid tags in source files.
  - [ ] Implement Laika-side compatibility interpretation only (no mass source rewrite yet).
- [ ] **Phase 2 (after parity gates):** transform Liquid usages to plain HTML marker tags/attributes in source (or preprocessed source), then map those markers to richer rendered components in Laika.
  - [ ] Example direction: transform `{% include youtube.html ... %}` into an HTML marker element or `data-component` block.
  - [ ] Keep transformation deterministic and idempotent.
- [ ] **Out of scope for Phase 1:** one-shot repo-wide syntax migration to native Laika HOCON/directives.

Why this plan: preserves Jekyll as a validation oracle during migration, then allows gradual source canonicalization once confidence is high.

### D2 - Theme strategy

- [ ] **Recommended:** do not rely on Helium layout defaults for the public site.
- [ ] Use custom `default.template.html` and local CSS/JS to preserve current visual identity.
- [ ] Optionally still use selected Helium capabilities where useful, but avoid inheriting Helium look and structure.

### D3 - Feed rendering strategy

- [ ] **Recommended:** separate parser and renderers and generate feeds as dedicated render artifacts (custom renderer or dedicated post-process step), not as ad-hoc string templates.
- [ ] Preserve exact field behavior and item ordering from current feed logic.

### D4 - URL strategy

- [ ] **Recommended:** enable pretty URLs and implement custom path translation where needed to preserve Jekyll permalink semantics.
- [ ] URL parity is a release gate, not a best effort.

### D5 - Build tool and code organization

- [ ] **Decision:** use Scala-CLI as the build driver.
- [ ] **Decision:** standardize on Scala 3 with scalac options `--no-indent --rewrite`.
- [ ] Keep a thin entry script for commands, but all substantial logic lives in top-level `src/**`.
- [ ] Avoid a monolithic single-file script architecture.

## 12) Laika API Blueprint (Implementation-Level)

This is the concrete API-level picture of what to implement.

### 12.0 Scala-CLI execution model

- [ ] Use Scala-CLI commands as the only build/serve entrypoint.
- [ ] Keep dependency declarations in the command entry script (or dedicated Scala-CLI directive file), while implementation is split across top-level `src/**`.
- [ ] Command surface should include at least:
  - [ ] `build` (render to `_site-laika` by default)
  - [ ] `serve` (preview server)
  - [ ] `verify` (parity checks against Jekyll output)

### 12.1 Core build pipeline (cats-effect + laika-io)

- [ ] Use `laika-io` + cats-effect and build a reusable `TreeTransformer[F]` resource.
- [ ] Baseline constructor shape:

```scala
import laika.api._
import laika.format._
import laika.io.syntax._

val transformer = Transformer
  .from(Markdown)
  .to(HTML)
  .using(Markdown.GitHubFlavor)
  .parallel[IO]
  .build
```

- [ ] Use `InputTree[IO]` composition (`addDirectory`, `addString`, `addClassResource`) for merging existing sources, generated artifacts, and compatibility-generated docs.
- [ ] Keep default Laika output target `_site-laika/` during migration; reserve `_site/` for release handoff only.

### 12.2 Parse/render separation for multi-output workflows

- [ ] Build with `MarkupParser.of(Markdown)...parallel[IO].build`.
- [ ] Reuse parsed tree for multiple outputs with:
  - [ ] `Renderer.of(HTML).withConfig(parser.config)...`
  - [ ] feed renderer pipeline (custom render format or post-process writer)
- [ ] Avoid reparsing content for each output target.

### 12.3 ExtensionBundle as primary migration hook

- [ ] Implement a dedicated bundle (e.g. `AlexnCompatBundle extends ExtensionBundle`) for:
  - [ ] custom directives / directive registry
  - [ ] AST rewrite rules
  - [ ] renderer overrides
  - [ ] path translation adjustments if required
- [ ] Register through `.using(AlexnCompatBundle)`.

### 12.4 Template system mapping

- [ ] Port layouts/includes to Laika templates using:
  - [ ] `default.template.html` (site default)
  - [ ] additional `*.template.html` files for page-type variants
- [ ] Use template substitution variables and template directives for dynamic sections.
- [ ] Preserve component boundaries from `_includes/` as template fragments/partials.

### 12.5 AST rewrite hooks for Jekyll parity

- [ ] Use `.usingSpanRule` / `.usingBlockRule` and/or `RewriteRules` for content-level transforms.
- [ ] Use `mapTree` / `TreeProcessor` for document-tree-level operations (e.g., generated indexes, feed-only or html-only mutations).
- [ ] Candidate rewrite responsibilities:
  - [ ] fence normalization (` ```scala reset ` -> ` ```scala `)
  - [ ] math marker recognition and replacement
  - [ ] content element rewrites currently done by HTML filters

### 12.6 Renderer override hooks for output-specific behavior

- [ ] Use `.rendering { case (fmt, elem) => ... }` for HTML-only custom rendering.
- [ ] Use `TagFormatter` APIs (`element`, `indentedElement`, `textElement`, `emptyElement`) for safe custom HTML output.
- [ ] Keep output-specific logic here only when AST-level rewrite is not appropriate.

### 12.7 Directives for include-like content macros

- [ ] Implement `DirectiveRegistry` with:
  - [ ] `SpanDirectives` / `BlockDirectives` for `youtube`, custom fragments, helper macros
  - [ ] `TemplateDirectives` for navigation and listing utilities
  - [ ] optional `LinkDirectives` for compact link shorthands
- [ ] Use directive DSL (`attribute(...)`, `parsedBody`, `rawBody`, `cursor`) for safe conversions and validation.

### 12.8 Path and URL translation

- [ ] Use built-in `PrettyURLs` where it aligns with current URL behavior.
- [ ] If needed, use `extendPathTranslator` in `ExtensionBundle` for custom path rules.
- [ ] Validate canonical URLs and feed links against current production behavior.

### 12.9 Preview and developer ergonomics

- [ ] Provide preview command via `laika.preview.ServerBuilder` + `ServerConfig`.
- [ ] Keep rapid local preview parity with current `jekyll serve` workflow.

---

## 13) Compatibility Layer Plan (YAML + Liquid + Jekyllisms)

This is the most important migration-specific work that pure Laika docs do not solve out of the box.

### 13.1 Front matter compatibility

- [ ] Implement YAML front matter extraction and conversion into Laika config values.
- [ ] Support mixed date formats currently used in repo.
- [ ] Preserve all front matter fields consumed by templates/feeds/filters.
- [ ] Add strict diagnostics for invalid metadata (fail fast in CI).

### 13.2 Liquid handling plan (deferred canonicalization)

- [ ] **Phase 1 (during dual-run):** do not rewrite source Liquid syntax yet.
  - [ ] Implement only the minimum Laika interpretation needed for parity.
  - [ ] Keep Jekyll build fully functional for side-by-side validation.
  - [ ] Add content linter that reports unresolved/unsupported Liquid constructs.
  - [ ] Lock a Phase 1 compatibility matrix to avoid scope creep:

| Construct | Phase 1 status | Behavior |
|---|---|---|
| `{% link ... %}` | supported | resolve to canonical internal URL or fail with diagnostic |
| `{% post_url ... %}` | supported | resolve post permalink using post index metadata |
| `{% include youtube.html ... %}` | supported | map to existing YouTube embed component |
| `{% raw %}...{% endraw %}` | supported | preserve literal body without Liquid interpretation |
| `{{ site.* }}`, `{{ page.* }}` (known keys) | supported | substitute from site/page metadata map |
| unknown `{% include ... %}` | lint-warning | render with compatibility fallback marker + warning |
| unsupported custom Liquid tags/filters | hard-fail | CI failure in strict mode |
- [ ] **Phase 2 (after parity approval):** implement deterministic Liquid -> plain HTML marker transformation.
  - [ ] Transform known tags to HTML markers/attributes:
    - [ ] `{% link ... %}`
    - [ ] `{% post_url ... %}`
    - [ ] `{% include youtube.html ... %}`
    - [ ] `{% raw %}...{% endraw %}` preservation semantics
  - [ ] Map marker HTML to richer rendered components through Laika directives/rewrite/render hooks.
  - [ ] Keep unsupported Liquid syntax policy explicit:
    - [ ] strict mode = fail fast
    - [ ] compatibility mode = controlled fallback

### 13.3 Liquid site/page variable replacements

- [ ] Replace `{{ site.* }}` and `{{ page.* }}` references used in pages/templates with Laika substitution variables or pre-expanded values.
- [ ] Ensure feed templates keep required escaping/encoding semantics.

---

## 14) Repository Layout Proposal for Laika Migration Code

- [ ] `build.scala` at repo root as a **thin Scala-CLI command entrypoint** (CLI wiring + dependencies only).
- [ ] Keep source layout flat under top-level `src/` (no `src/main/scala`, no org-style nesting).
- [ ] `src/Build.scala` (pipeline orchestration).
- [ ] `src/extensions/`:
  - [ ] `CompatBundle.scala`
  - [ ] `Directives.scala`
  - [ ] `RenderOverrides.scala`
  - [ ] `PathTranslation.scala`
  - [ ] `FeedRenderer.scala`
- [ ] `src/compat/`:
  - [ ] `YamlFrontMatter.scala`
  - [ ] `LiquidTranslator.scala`
  - [ ] `ContentAudit.scala`
- [ ] `src/templates/`:
  - [ ] `default.template.html`
  - [ ] page/post/wiki/feed templates
- [ ] Keep static assets at top level (`assets/`, `feeds/`, `docs/`, root files) and wire them via `InputTree.addDirectory(...)` mappings.
- [ ] `src/` is reserved for Scala source files and template code only.
- [ ] No `sbt` files required for the migration path.

---

## 15) Validation Gates (Must Pass Before Cutover)

### Gate A - URL and redirects

- [ ] 100% of known URLs resolve to expected target/status behavior.
- [ ] Generated `_redirects` and `nginx.conf` sections diff-clean vs baseline intent.

### Gate B - Feed parity

- [ ] All 5 feeds validate as XML.
- [ ] Item order, `<guid>`, `<pubDate>`, category/tag emission, and campaign URLs match expected semantics.
- [ ] Math image variant switching (transparent vs white) verified in feed content.
- [ ] Feed comparator runs in semantic mode with explicit normalization rules from section 6.1.

### Gate C - Content rendering parity

- [ ] Representative sample set includes:
  - [ ] math posts
  - [ ] youtube include posts
  - [ ] legacy HTML posts
  - [ ] wiki pages with heavy `{% link %}` usage
- [ ] No unresolved Liquid artifacts in rendered HTML.
- [ ] HTML comparator uses normalized DOM checks with explicit ignore list from section 6.1.

### Gate D - Asset/runtime behavior

- [ ] managed JS assets present and loadable.
- [ ] syntax highlighting works for existing language set.
- [ ] comments/embed/tracking scripts preserved where intended.

### Gate E - Operational readiness

- [ ] CI runtime acceptable and stable.
- [ ] Per-PR GitHub Actions includes a required Scala/Laika build check for migration PRs.
- [ ] local preview workflow documented.
- [ ] rollback plan tested at least once.
