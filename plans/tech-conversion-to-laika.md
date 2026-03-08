# Switch from Jekyll to Laika

This website uses Jekyll as a "static website generator". I want it converted to Laika:
https://typelevel.org/Laika/

- In the `./plans/` folder from project's root I have downloaded `laika-1.x-library.epub` for learning how to use it.
- You can get inspiration from https://github.com/typelevel/typelevel.github.com/ (just an example, that doesn't mean copying its code)

All this website's features have to be preserved:
- Categories (e.g., blog, wiki)
- Article tags
- Feeds (see `./feeds/`)
- Website design (see `_layouts`, `_sass`)
- Pay attention to functionality described in `_plugins/`
- Pay attention to Node integration (for bringing in dependencies such as MathJax)