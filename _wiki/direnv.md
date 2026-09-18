---
date: 2026-05-16 12:31:13 +03:00
last_modified_at: 2026-05-19T17:33:20+03:00
---

# Direnv

```
brew install direnv
```

Normally, to make it also work with `.env` files, this can be configured in `~/.config/direnv/direnv.toml`:

```toml
[global]
load_dotenv = true
```

Unfortunately, it has [issues](https://github.com/direnv/direnv/issues/1570) with 1Password's [Developer Environments](https://www.1password.dev/environments), so for each `.env` I'm creating a companion `.envrc` file:

```bash
set -a; source .env; set +a
```
