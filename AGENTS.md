# AGENTS.md

Use `plans/tech-conversion-to-laika.md` for migration scope and sequencing.

## Scala and Build Rules

- Build tool is `Scala-CLI` only. Do not add `sbt` files.
- Use Scala 3.
- Required scalac options: `--no-indent --rewrite`.
- Keep `build.scala` at repo root as a thin entrypoint.
- For keeping Scala dependencies up to date: 
  `scala-cli --power dependency-update ./build.scala --all` 
- Verify that Scala code compiles: 
  `scala-cli compile ./build.scala`.

## Project Organization Rules

- Keep migration implementation in top-level `src/`.
- Do not use `site/` for migration source code.
- Do not use `src/main/scala` nesting.
- `src/` should contain Scala source files and template code only.
- Keep static assets in existing top-level folders (`assets/`, `feeds/`, `docs/`, root files), wired via Laika `InputTree`.

## Required Skills

- `cats-effect-io`
- `cats-effect-resource`

Use `cats-effect-io` patterns for effectful orchestration and safe I/O boundaries, and `cats-effect-resource` for acquire/use/release lifecycles.
