---
date: 2020-08-24 16:24:31 +03:00
last_modified_at: 2026-10-05T12:01:06+03:00
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

## Git repos with different SSH key for authentication & signing

Let's say we have this non-default identity file: `~/.ssh/id_corp.pub`

All commands below are run with plain `git config` (no `--global`), so they apply only to this repository's `.git/config`.

### Commit signing (agent-agnostic)

```bash
git config user.signingKey "$(cat ~/.ssh/id_corp.pub)"
git config gpg.format ssh
git config commit.gpgsign true
```

Git passes this public key to `ssh-keygen -Y sign`, which asks whatever agent is on `SSH_AUTH_SOCK` for the matching private key.

### Transport authentication (`origin` over SSH)

```bash
git config core.sshCommand "ssh -i ~/.ssh/id_corp.pub -o IdentitiesOnly=yes"
```

If having issues, might want to specify the agent explicitly:

```bash
# 1Password
git config core.sshCommand 'ssh -i ~/.ssh/id_corp.pub -o IdentitiesOnly=yes -o IdentityAgent="~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'

# Bitwarden
git config core.sshCommand "ssh -i ~/.ssh/id_corp.pub -o IdentitiesOnly=yes -o IdentityAgent=~/.bitwarden-ssh-agent.sock"
```

### Verification

```bash
GIT_SSH_COMMAND="$(git config core.sshCommand) -v" git fetch origin
git log --show-signature -1
```
