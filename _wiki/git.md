---
date: 2020-08-24 16:24:31 +03:00
last_modified_at: 2026-09-07 17:19:36 +03:00
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

## Mirroring

```
git clone --mirror <origin-url> ~/git-remotes/project.git
```

Cloning the mirror as the origin:

```
git clone --no-local ~/git-remotes/project.git /workspace/project
```

### Sync origin -> workspace

```
cd ~/git-remotes/project.git
git fetch --prune
```

Then inside the workspace:

```
git fetch origin 
git pull --rebase origin main
```

### Sync workspace -> origin

In `/workspace/project`:
```
git push origin <branch>
```

Then:
```
cd ~/git-remotes/project.git
git push --mirror
```

### Merge conflicts

Conflicts get solved in the workspace's directory.

```
# edit conflicted files 
git add <files> 
git rebase --continue
# ...
git push origin <branch>
```

Then publish from mirror to origin:

```
cd ~/git-remotes/project.git
git push --mirror
```
