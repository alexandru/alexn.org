---
date: 2020-08-24 16:24:31 +03:00
last_modified_at: 2022-09-01 17:21:01 +03:00
---

# Git

## Commands

Cleanup a local repository of all untracked files:

```
git clean -dfx
```

Throw away all uncommitted changes:

```
git reset --hard HEAD
```

## Large files support

Resources:

- [Project homepage](https://git-lfs.github.com/)
- [Versioning large files](https://docs.github.com/en/github/managing-large-files/versioning-large-files)

Installation:

```
brew install git-lfs
```

In the git repository:

```
git lfs install
```

To add file extensions to track via "lfs":

```
git lfs track "*.psd"
```

## git-sync

- [Automated Syncing with Git](https://worthe-it.co.za/programming/2016/08/13/automated-syncing-with-git.html)
- [github.com/simonthum/git-sync](https://github.com/simonthum/git-sync)
