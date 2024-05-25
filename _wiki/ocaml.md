---
date: 2024-04-15 20:23:07 +03:00
last_modified_at: 2024-04-15 20:27:49 +03:00
---

# OCaml

## Installing

For macOS ([see other platforms](https://opam.ocaml.org/doc/Install.html)):
```sh
brew install opam
```

Initialize:
```sh
opam init

# Test
opam switch
```

Some utilities:
```sh
# For the VS Code extension (OCaml Platform)
opam install ocaml-lsp-server

# OCaml REPL
opam install utop

# Standard library recommended by Real World OCaml
opam install core core_bench
```

