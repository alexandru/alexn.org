package extensions

import laika.api.bundle.ExtensionBundle

/** Compatibility extension bundle for the Jekyll → Laika migration.
  *
  * During the dual-run phase (W1–W11) this bundle provides:
  *   - YAML front-matter extraction and mapping to Laika config values.
  *   - Compatibility interpretation of Liquid constructs kept in source
  *     content ({% link %}, {% post_url %}, {% include youtube.html %},
  *     {% raw %}…{% endraw %}).
  *   - AST rewrite hooks (fence header normalisation, math markers, etc.).
  *   - Renderer overrides for output-specific behaviour.
  *   - Custom directives (YouTube embed, contribution/subscription blocks).
  *
  * New workstream implementations (W2-W12) will be added here
  * incrementally without changing the public API surface.
  */
object CompatBundle extends ExtensionBundle {

  override val description: String =
    "alexn.org Jekyll compatibility bundle"
}
