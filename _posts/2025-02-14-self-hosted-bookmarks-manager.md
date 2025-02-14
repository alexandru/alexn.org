---
title: "Self-hosted Bookmarks Manager"
date: 2025-02-14T07:03:54+02:00
last_modified_at: 2025-02-14T07:23:09+02:00
tags:
  - Docker
  - Open Source
  - Self Hosting
  - Server
  - Web
description: >
  I like having a database of links I encounter on the web, like a searchable database, complete with archive links as well. I found a solution.
---

<p class="intro">
  I like having a database of links I encounter on the web, like a searchable database, complete with archive links as well. I found a solution.
</p>

Storing bookmarks in your browser is OK, especially if you use a solution for synchronizing that archive, such as [floccus](https://floccus.org/) ([GitHub](https://github.com/floccusaddon/floccus)), but that's not enough, as I also want it to be searchable (with tags and descriptions) and shareable. I used Pinboard, Pocket, private notes, [wiki notes](../_wiki/teach-kids.md) and I even tried a links section on this blog.

I finally found a Pinboard-like replacement that I can easily self-host and that's just perfect for my needs: [linkding](https://linkding.link/) ([GitHub link](https://github.com/sissbruecker/linkding)).

My links are now hosted here: [links.alexn.org](https://links.alexn.org/) ([RSS feed](https://links.alexn.org/feeds/shared)).

## Setup

The official [installation instructions](https://linkding.link/installation/) are pretty good, but in case it helps, what follows is my setup.

Entry in my `docker-compose.yaml`:

```yaml
linkding:
  container_name: linkding
  image: sissbruecker/linkding:latest
  restart: unless-stopped
  healthcheck:
    test: ["CMD-SHELL", "curl --silent --fail http://localhost:9090/health || exit 1"]
  ports:
    - "3009:9090"
  volumes:
    - 'linkding:/etc/linkding/data'
  networks:
    - external_network
```

My Nginx reverse-proxy setup:

```conf
location / {
    root   /var/www/links.alexn.org;
    include ./snippets/cloudflare-ips.conf;
    
    proxy_pass http://0.0.0.0:3009;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;

    # Prevent Cloudflare from caching while allowing client caching
    add_header Cache-Control "private, no-transform";
    add_header CDN-Cache-Control "no-store, no-cache";  # Cloudflare-specific
    add_header Cloudflare-CDN-Cache-Control "no-store"; # Cloudflare-specific
}

location /static/ {
    root   /var/www/links.alexn.org;
    include ./snippets/cloudflare-ips.conf;
    
    proxy_pass http://0.0.0.0:3009;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # Nginx caching
    proxy_cache CACHE;
    proxy_cache_use_stale error timeout http_500 http_502 http_503 http_504;
    proxy_cache_valid 200 302 30d;
    proxy_cache_valid 404 1m;
    proxy_cache_key $host$request_uri;
    
    # Cache settings for browsers and CDN
    expires 30d;
    add_header Cache-Control "public, no-transform";
    add_header Vary Accept-Encoding;
    add_header X-Cache-Status $upstream_cache_status; # Optional: helps with debugging
}
```

I'm also doing targeted [server backups](./2022-12-02-personal-server-backups.md), so here's the script that I'm periodically executing via cron:

```bash
#!/bin/bash

set -e

FILENAME="linkding-$(date +"%Y-%m").zip"
FILEPATH="/var/lib/my-backups/$FILENAME"
CONTAINER_BACKUP="/etc/linkding/data/backup.zip"

if [ "{% raw %}$(docker inspect -f '{{.State.Running}}' linkding){% endraw %}" ]; then
  echo "[$(date +"%Y-%m-%d %H:%M:%S%z")] Generating $FILEPATH"
  docker exec -it linkding python manage.py full_backup "$CONTAINER_BACKUP"
  docker cp linkding:"$CONTAINER_BACKUP" "$FILEPATH"
  docker exec linkding rm -f "$CONTAINER_BACKUP"

  if [ -f "$FILEPATH" ]; then
    rclone copy "$FILEPATH" "backup:AlexnOrg/Linkding/"
  fi
fi

rm -f /var/lib/my-backups/linkding-*.zip
```

With the cron entry being like:

```
50 */6 * * * root cronic /path/to/bin/vm-backup-linkding
```

Ensure to [auto-upgrade it](./2025-02-14-updating-docker-containers.md) as well.
