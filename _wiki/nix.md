---
title: "Nix"
date: 2020-08-24 16:24:31 +03:00
last_modified_at: 2022-03-29 10:43:35 +03:00
---

## Install/Uninstall instructions

Install with:

``` sh
sh <(curl https://nixos.org/nix/install) --darwin-use-unencrypted-nix-store-volume
```

To uninstall:

1. Remove the entry from `fstab` using `sudo vifs`
2. Destroy the data volume using `diskutil apfs deleteVolume`
3. Remove the `nix` line from `/etc/synthetic.conf` or the file

## Resources

- [Nix configuration for a Scala project](https://github.com/functional-streams-for-scala/fs2/blob/main/shell.nix)
- [Moving from Homebrew to Nix Package Manager](https://www.softinio.com/post/moving-from-homebrew-to-nix-package-manager/)
- [Nix sample config](https://github.com/gvolpe/nix-config)
- [Nix tutorial](https://nix-tutorial.gitlabpages.inria.fr/nix-tutorial/index.html)
- [Environments with Nix Shell](https://github.com/samdroid-apps/nix-articles)

## Aliases

``` sh
alias nix-env-search="nix-env -qaP"
alias nix-env-install="nix-env -iA"
alias nix-env-update-all="nix-channel --update nixpkgs && nix-env -u '*'"
alias nix-up="nix-env -u"
alias nix-gc="nix-collect-garbage -d"
```

## Nix-env Cheatsheet

List installed packages:

```
nix-env --query --installed
```

To search for packages:

https://nixos.org/nixos/packages.html?channel=nixpkgs-unstable

To install a certain package:

```
nix-env -iA nixpkgs.ripgrep
```

Uninstall:

```
nix-env -e tree ripgrep
```

List generations (all of the different versions of the nix-env profile):

```
nix-env --list-generations
```

To rollback to a previous version of the profile:

```
nix-env --rollback
```

Or pick a specific generation:

```
nix-env --switch-generation 2
```

To use a program without installing it, we can create a temporary
environment with `nix-shell` (in this case `tectonic` is the name of
the package we want):

```
nix-shell '<nixpkgs>' -A tectonic
```

To update all packages:

``` sh
nix-channel --update nixpkgs
nix-env -u '*'
```

## Nix-shell Cheatsheet

To enable `nix-shell` for a project, define a `default.nix` in the project's root, like so:

``` nix
# This imports the nix package collection,
# so we can access the `pkgs` and `stdenv` variables
with import <nixpkgs> {};

# Make a new "derivation" that represents our shell
stdenv.mkDerivation {
  name = "fpinscala-courses";

  # The packages in the `buildInputs` list will be added to the PATH in our shell
  buildInputs = [
    # see https://nixos.org/nixos/packages.html to search for more
    pkgs.tectonic
    pkgs.cmake
  ];
}
```

Then execute `nix-shell` in the directory.
