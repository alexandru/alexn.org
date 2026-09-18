---
date: 2020-08-24 16:24:31 +03:00
last_modified_at: 2026-09-17T08:32:13+03:00
---

# Rust

## Installation

See [documentation](https://www.rust-lang.org/tools/install).

To update Rust:

```
rustup update
```

To uninstall:

```
rustup self uninstall
```

## Tools, Libraries

Build tools:

- [rust-clippy](https://github.com/rust-lang/rust-clippy): linting for catching common mistakes;
- [rustfmt](https://github.com/rust-lang/rustfmt): automatic code formatting;

Fun stuff:

- [Neon: Write fast, safe native Node plugins with Rust](https://neon-rs.dev/);
- [Bevy - Game Engine](https://bevyengine.org/);

Web:

- [Leptos](https://leptos.dev/);
- [Rocket](https://rocket.rs/);
- [Other](https://www.arewewebyet.org/).

## Documentation

- [The Rust Programming Language](https://doc.rust-lang.org/): official book for beginners
- [Rust by Example](https://doc.rust-lang.org/rust-by-example/): another official book
- [Learn Rust With Entirely Too Many Linked Lists](https://rust-unofficial.github.io/too-many-lists/)
- [Asynchronous Programming in Rust](https://rust-lang.github.io/async-book/)
- [Rust Sokoban](https://sokoban.iolivia.me/)
- [Tour of Rust](https://tourofrust.com/)

## Exercises

- [Rustlings](https://github.com/rust-lang/rustlings/)

## Tutorials

- [Choosing Rust - Intro to Rust and Ownership](https://www.youtube.com/watch?v=DMAnfOlhSpU) (YouTube video)

## How-to

### Cargo

To start a new project:

```
cargo new hello_world
```

To build:

```sh
cargo build

# To build for release:

cargo build --release

# Type checks (faster than "build"):

cargo check
```

To compile and execute the project:

```sh
cargo run
```

To update dependencies:

```sh
cargo update
```

To generate and show the documentation of all dependencies:

```sh
cargo doc --open
```

### Language Server

```sh
rustup component add rust-analyzer
```

### Build executable scripts

```rust
#!/usr/bin/env -S cargo +nightly -q -Zscript

---cargo
[package]
edition = "2024"

[dependencies]
anyhow = "1"
clap = { version = "4", features = ["derive"] }
---

use anyhow::Result;
use clap::Parser;

#[derive(Parser)]
struct Args {
    name: String,
}

fn main() -> Result<()> {
    let args = Args::parse();
    println!("Hello, {}!", args.name);
    Ok(())
}
```
