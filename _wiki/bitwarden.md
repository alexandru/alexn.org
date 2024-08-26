---
date: 2024-08-26 13:45:19 +03:00
last_modified_at: 2024-08-26 17:46:39 +03:00
---

# Bitwarden / Vaultwarden

## Self-hosting (Vaultwarden)

See [documentation](https://github.com/dani-garcia/vaultwarden/wiki).

Setup for `docker-compose.yaml`:

```yaml
vaultwarden:
  container_name: vaultwarden
  image: vaultwarden/server:latest
  restart: always
  healthcheck:
    test: ['CMD-SHELL', 'curl --silent --fail http://localhost:80/ || exit 1']
  ports:
    - "3201:80"
  volumes:
    - vaultwarden:/data
  networks:
    - external_network
  env_file:
    - ./envs/vaultwarden.env
```

Related `./envs/vaultwarden.env` file:

```bash
##
# Documentation:
# https://github.com/dani-garcia/vaultwarden/wiki/Enabling-admin-page
#
# To generate:
# echo -n "MySecretPassword" | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4
#
ADMIN_TOKEN=

##
# https://github.com/dani-garcia/vaultwarden/wiki/Disable-registration-of-new-users
#
SIGNUPS_ALLOWED=false

##
# https://github.com/dani-garcia/vaultwarden/wiki/SMTP-Configuration
#
# NOTE: Hetzner and other cloud providers, are blocking port 467
# https://www.fastmail.help/hc/en-us/articles/1500000278342-Server-names-and-ports
#
SMTP_HOST=smtp.fastmail.com
SMTP_PORT=587
SMTP_SECURITY=starttls
SMTP_FROM=
SMTP_USERNAME=
SMTP_PASSWORD=

##
# https://github.com/dani-garcia/vaultwarden/wiki/Enabling-Mobile-Client-push-notification
# https://bitwarden.com/host/
#
PUSH_RELAY_URI=https://api.bitwarden.eu
PUSH_IDENTITY_URI=https://identity.bitwarden.eu
PUSH_ENABLED=true
PUSH_INSTALLATION_ID=
PUSH_INSTALLATION_KEY=
```

My Nginx reverse proxy configuration:

```conf
root /var/www/vault.nedelcu.net;
log_not_found off;

include ./snippets/gzip.conf;

location / {
    proxy_pass http://vaultwarden;
    include ./snippets/proxy-backend.conf;
}
```

Where `./snippets/proxy-backend.conf` is:

```conf
include ./snippets/cloudflare-ips.conf;

proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header Proxy "";
proxy_pass_header Server;

proxy_buffering on;
proxy_redirect off;
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection $connection_upgrade;

proxy_cache CACHE;
proxy_cache_valid 200 7d;
proxy_cache_valid 410 24h;
proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;

add_header X-Cached $upstream_cache_status;
tcp_nodelay on;
```

For `./snippets/cloudflare-ips.conf` see [Restoring original visitor IPs (Cloudflare.com)](https://developers.cloudflare.com/support/troubleshooting/restoring-visitor-ips/restoring-original-visitor-ips/).

## CLI commands

Installation for macOS:

```
brew install bitwarden-cli jq
```

Lists items in the order they were modified:

```bash
bw list items | jq '[.[] | {name: .name, date: .revisionDate}] | sort_by(.date)'
```

Lists items with [passkeys](https://www.passkeys.io/) defined:

```bash
bw list items | jq '.[] | select(.login.fido2Credentials | length > 0) | {name: .name, id: .id, updated: .revisionDate}'
```
