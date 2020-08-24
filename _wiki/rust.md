# Rust - Getting Started

<!-- toc -->

- [Installation](#installation)
- [Documentation](#documentation)
- [Tools](#tools)
  - [Cargo](#cargo)
  - [Language Server](#language-server)

<!-- tocstop -->

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

## Documentation

- [The Rust Programming Language](https://doc.rust-lang.org/)
- [Learn Rust With Entirely Too Many Linked Lists](https://rust-unofficial.github.io/too-many-lists/)
- [Asynchronous Programming in Rust](https://rust-lang.github.io/async-book/)
- [Rust Sokoban](https://sokoban.iolivia.me/)
- [Tour of Rust](https://tourofrust.com/)

## Tools

### Cargo

To start a new project:

```
cargo new hello_world
```

To build:

```sh
carbo build

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
rustup component add rls
```
