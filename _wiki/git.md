---
date: 2020-08-24 16:24:31 +03:00
last_modified_at: 2026-09-07 19:04:59 +03:00
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

For the purposes of working in a Docker container with a macOS host:

```bash
# macOS: initial corporate clone
git clone --mirror <corporate-origin-url> /path/to/project.git

# macOS: allow branch-specific pushes
git -C /path/to/project.git config remote.origin.mirror false

# Docker: clone from the mounted macOS bare repo
git clone --no-local /git/project.git /workspace/project
cd /workspace/project


# Docker -> macOS bare repo
git push origin <branch>

# macOS bare repo -> corporate origin
git-up /path/to/project.git <branch>


# corporate origin -> macOS bare repo
git-down /path/to/project.git <branch>

# macOS bare repo -> Docker
git pull origin <branch>


# If git-down reports divergence
git fetch origin \
  refs/remotes/origin/<branch>:refs/remotes/corporate/<branch>

git merge corporate/<branch>
# or
git rebase corporate/<branch>

# Resolve, then
git add <files>
git commit
# or, for rebase
git rebase --continue

# Publish resolved branch
git push origin <branch>
git-up /path/to/project.git <branch>
```

`~/bin/git-up`:
```bash
#!/usr/bin/env bash
set -uo pipefail

usage() {
  echo "Usage: $(basename "$0") <repo.git> <branch>" >&2
  exit 2
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

[[ $# -eq 2 ]] || usage

repo="$1"
branch="$2"
ref="refs/heads/$branch"

command -v git >/dev/null 2>&1 ||
  die "git is not installed or not in PATH"

[[ -d "$repo" ]] ||
  die "Repository does not exist: $repo"

git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 ||
  die "Not a Git repository: $repo"

[[ "$(git -C "$repo" rev-parse --is-bare-repository)" == "true" ]] ||
  die "Expected a bare Git repository: $repo"

git check-ref-format --branch "$branch" >/dev/null 2>&1 ||
  die "Invalid branch name: $branch"

git -C "$repo" remote get-url origin >/dev/null 2>&1 ||
  die "Remote 'origin' is not configured"

git -C "$repo" show-ref --verify --quiet "$ref" ||
  die "Local branch does not exist: $branch"

echo "Pushing '$branch' to origin..."

if ! git -C "$repo" \
    -c remote.origin.mirror=false \
    push origin "$ref:$ref"
then
  cat >&2 <<EOF

ERROR: Push failed.

Possible causes:
  - origin contains commits not present locally
  - authentication/credentials failed
  - origin is unreachable
  - the branch is protected

No local refs were modified.
EOF
  exit 1
fi

echo "Successfully pushed '$branch'."
```

`~/bin/git-down`:
```bash
#!/usr/bin/env bash
set -uo pipefail

usage() {
  echo "Usage: $(basename "$0") <repo.git> <branch>" >&2
  exit 2
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

[[ $# -eq 2 ]] || usage

repo="$1"
branch="$2"

local_ref="refs/heads/$branch"
origin_ref="refs/remotes/origin/$branch"
remote_ref="refs/heads/$branch"

command -v git >/dev/null 2>&1 ||
  die "git is not installed or not in PATH"

[[ -d "$repo" ]] ||
  die "Repository does not exist: $repo"

git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 ||
  die "Not a Git repository: $repo"

[[ "$(git -C "$repo" rev-parse --is-bare-repository)" == "true" ]] ||
  die "Expected a bare Git repository: $repo"

git check-ref-format --branch "$branch" >/dev/null 2>&1 ||
  die "Invalid branch name: $branch"

git -C "$repo" remote get-url origin >/dev/null 2>&1 ||
  die "Remote 'origin' is not configured"

echo "Fetching '$branch' from origin..."

if ! git -C "$repo" \
  fetch origin "$remote_ref:$origin_ref"
then
  die "Could not fetch '$branch' from origin"
fi

origin_commit="$(git -C "$repo" rev-parse "$origin_ref")" ||
  die "Could not resolve fetched origin branch"

#
# Branch doesn't exist locally yet.
#
if ! git -C "$repo" show-ref --verify --quiet "$local_ref"; then
  git -C "$repo" update-ref "$local_ref" "$origin_commit" ||
    die "Could not create local branch '$branch'"

  echo "Created local '$branch'."
  exit 0
fi

local_commit="$(git -C "$repo" rev-parse "$local_ref")" ||
  die "Could not resolve local branch '$branch'"

#
# Already identical.
#
if [[ "$local_commit" == "$origin_commit" ]]; then
  echo "'$branch' is already up to date."
  exit 0
fi

#
# Local is behind origin: safe fast-forward.
#
if git -C "$repo" merge-base --is-ancestor \
  "$local_commit" "$origin_commit"
then
  git -C "$repo" update-ref \
    "$local_ref" \
    "$origin_commit" \
    "$local_commit" ||
      die "Could not fast-forward '$branch'"

  echo "Fast-forwarded '$branch'."
  exit 0
fi

#
# Local is ahead: nothing to pull.
#
if git -C "$repo" merge-base --is-ancestor \
  "$origin_commit" "$local_commit"
then
  echo "Local '$branch' is ahead of origin; nothing to pull."
  exit 0
fi

#
# Diverged.
#
cat >&2 <<EOF
ERROR: '$branch' has diverged from origin.

Local:
  $local_commit

Origin:
  $origin_commit

The local branch was NOT modified.

The origin version is available as:
  $origin_ref

Resolve the divergence in your Docker working clone.
EOF

exit 1
```