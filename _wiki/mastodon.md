---
date: 2022-11-22 11:55:19 +02:00
last_modified_at: 2023-08-02 11:12:06 +03:00
---

# Mastodon

## Twitter migration

<p class="warn-bubble" markdown="1">
**WARN:** Mastodon ain't Twitter. Its design and available features are slightly different, as a matter of philosophy.
</p>

### Instances

Mastodon is "federated". At [joinmastodon.org](https://joinmastodon.org/) you can find a list of instances available, but it's not complete.

It's a good idea to prefer alternatives to [mastodon.social](https://mastodon.social), because this server is being hammered by new traffic. On the other hand, instances are servers maintained by volunteers, so it's best to find some properly maintained ones.

For professionals in the software industry, these instances seem to be pretty good:

- [fosstodon.org](https://fosstodon.org/) (English-only)
- [hachyderm.io](https://hachyderm.io/)

Some smaller instances you might want to consider:

- [functional.cafe](https://functional.cafe/)
- [indieweb.social](https://indieweb.social/)
- [types.pl](https://types.pl)

### Getting started resources

- [How To Use Mastodon and the Fediverse: Basic Tips](https://fedi.tips/how-to-use-mastodon-and-the-fediverse-basic-tips/);
- [Quick-start guide](https://blog.joinmastodon.org/2018/08/mastodon-quick-start-guide/);
- [An Increasingly Less-Brief Guide to Mastodon](https://github.com/joyeusenoelle/GuideToMastodon/);

### Available apps

- The website works well on mobile too;
- On Android, the official app isn't very good for now, prefer [Tusky](https://play.google.com/store/apps/details?id=com.keylesspalace.tusky&pli=1);
- See list of [available apps](https://joinmastodon.org/apps);

### Utilities

Browser extension that redirects you from Mastodon4 instances to your home instance (makes it easier to follow people):<br>
[mastodon4-redirect](https://github.com/raikasdev/mastodon4-redirect) ([Firefox](https://addons.mozilla.org/en-US/firefox/addon/mastodon4-redirect/){:target="_blank"}, [Chrome](https://chrome.google.com/webstore/detail/mastodon4-redirect/acbfckpoogjdigldffcbldijhgnjpfnc){:target="_blank"}).

To find your Twitter friends on Mastodon: <br>
<https://fedifinder.glitch.me>

For the cool factor, implement "WebFinger" on your own domain: <br>
<https://rossabaker.com/projects/webfinger/>

For following Twitter's drama, without logging into Twitter: <br>
<https://twitterisgoinggreat.com>

### Download Twitter archive

Download your Twitter archive and store it somewhere safe, even if you don't plan on leaving Twitter: <br>
<https://twitter.com/settings/download_your_data>

The archive download is fairly usable. But you might want to parse your archive, to replace `t.co` links and spit out markdown files:

- [Converting Your Twitter Archive to Markdown](https://matthiasott.com/notes/converting-your-twitter-archive-to-markdown)
- [twitter-archive-parser (GitHub)](https://github.com/timhutton/twitter-archive-parser)

### Leaving Twitter?

First download your Twitter archive and store it somewhere safe: <br>
<https://twitter.com/settings/download_your_data>

If you'd like to delete your Twitter account, depending on how popular your account is, you might want to avoid deleting it, to prevent impersonation/cybersquatting. I recommend to:

1. Download your Twitter archive;
2. Delete all your tweets: <https://tweetdelete.net>
3. Modify your profile to inform your visitors that you moved;
4. Maybe also lock your account, to prevent new followers;

## Self-Hosting

I'm hosting my own Mastodon instance at <https://social.alexn.org>.
This is my own configuration, tuned to my needs...

### Services used

- [Hetzner](https://www.hetzner.com/cloud), for a VPS with 4 GB of RAM and
  40 GB of disk space; 2 GB should be fine, but it may need a swap setup;
  I might also need more disk space in the future, or block storage;
- [Cloudflare](https://www.cloudflare.com/) because it can save you bandwidth
  (must ensure correct caching setup);
- [Fastmail](https://www.fastmail.com/) for sending emails via SMTP, as I was
  already using it for my personal email, and supports SMTP-only passwords;
- [Backblaze B2](https://www.backblaze.com/cloud-storage) for backups
  and potentially for storing cached files;

### Docker (docker-compose)

```yaml
version: '3.8'

services:
  redis:
    container_name: redis
    image: redis:7
    restart: unless-stopped
    command: /bin/sh -c "redis-server --appendonly yes --requirepass $$REDIS_PASSWORD"
    healthcheck:
      test: ['CMD', 'redis-cli', '-a', '$$REDIS_PASSWORD', 'ping']
    volumes:
      - redis:/data
    networks:
      - internal_network
    sysctls: # https://github.com/docker-library/redis/issues/191#issuecomment-528693994
      - net.core.somaxconn=511
    env_file:
      ./envs/redis.env

  postgresdb:
    container_name: postgresdb
    image: 'postgres:15-alpine'
    healthcheck:
      test: ['CMD', 'pg_isready', '-U', 'postgres']
    volumes:
      - 'postgres-db:/var/lib/postgresql/data'
    restart: unless-stopped
    env_file:
      - ./envs/postgres.env
    networks:
      - internal_network

  mastodon-web:
    container_name: mastodon-web
    image: 'tootsuite/mastodon:latest'
    command: 'bash -c "bundle exec rake db:migrate && rm -f /mastodon/tmp/pids/server.pid && bundle exec rails s -p 3000"'
    ports:
      - 3000:3000
    restart: unless-stopped
    healthcheck:
      test: ['CMD-SHELL', 'wget -q --spider --proxy=off localhost:3000/health || exit 1']
    volumes:
      - 'mastodon-volume:/mastodon/public/system'
    env_file:
      - ./envs/mastodon.env
    depends_on:
      - postgresdb
      - redis
    networks:
      - internal_network
      - external_network

  mastodon-sidekiq:
    container_name: mastodon-sidekiq
    image: 'tootsuite/mastodon'
    command: 'bundle exec sidekiq'
    restart: unless-stopped
    healthcheck:
      test: ['CMD-SHELL', "ps aux | grep '[s]idekiq\ 6' || false"]
    volumes:
      - 'mastodon-volume:/mastodon/public/system'
    env_file:
      - ./envs/mastodon.env
    depends_on:
      - postgresdb
      - redis
    networks:
      - internal_network
      - external_network

  mastodon-streaming:
    container_name: mastodon-stream
    image: 'tootsuite/mastodon'
    restart: unless-stopped
    command: node ./streaming
    healthcheck:
      test: ['CMD-SHELL', 'wget -q --spider --proxy=off localhost:4000/api/v1/streaming/health || exit 1']
    ports:
      - '127.0.0.1:4000:4000'
    env_file:
      - ./envs/mastodon.env
    depends_on:
      - postgresdb
      - redis
    networks:
      - external_network
      - internal_network

networks:
  external_network:
  internal_network:
    internal: true

volumes:
  redis:
  postgres-db:
  mastodon-volume:
```

File `redis.env` for the Redis database:

```sh
REDIS_PASSWORD="<your redis pass>"
```

File `postgres.env` for the Postgres database:

```sh
POSTGRES_PASSWORD="<password for 'postgres' admin>"
```

File `mastodon.env`:

```sh
RAILS_ENV="production"
LOCAL_DOMAIN="social.alexn.org"
# WEB_DOMAIN="social.alexn.org"

# Must create DB user and database
DB_HOST="postgresdb"
DB_NAME="mastodon"
DB_USER="mastodon"
DB_PASS=

# Must reuse the password from `redis.env`
REDIS_URL="redis://default:password@redis:6379"

# -----------
# App Secrets
# -----------
# Can be generated with:
# docker-compose run --rm mastodon-web bundle exec rake secret
# -----------
SECRET_KEY_BASE=
OTP_SECRET=

# ----------------------
# Web Push Notifications
# ----------------------
# Generate with `rake mastodon:webpush:generate_vapid_key`
#
# docker exec mastodon-web bundle exec rake mastodon:webpush:generate_vapid_key
# ----------------------
VAPID_PRIVATE_KEY=
VAPID_PUBLIC_KEY=

# --------
MASTODON_ADMIN_USERNAME="alexelcu"
MASTODON_ADMIN_EMAIL="alexelcu@social.alexn.org"

# ------------------------------------------
# Email settings / via external SMTP service
# ------------------------------------------
# See Fastmail's App Passwords:
# https://www.fastmail.help/hc/en-us/articles/360058752854-App-passwords
# ------------------------------------------
SMTP_SERVER="smtp.fastmail.com"
SMTP_PORT=465
SMTP_FROM_ADDRESS="noreply@social.alexn.org"
SMTP_LOGIN=
SMTP_PASSWORD=

# --------------------------------
# For enabling cloud block storage
# --------------------------------
# S3_ENABLED=true
# S3_PROTOCOL=https
# S3_ENDPOINT=https://s3.eu-central-003.backblazeb2.com
# S3_HOSTNAME=s3.eu-central-003.backblazeb2.com
# S3_BUCKET=alexn-social-files
# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=
# S3_ALIAS_HOST="files-social.alexn.org"
```

### Postgres Setup

To create the database for Mastodon, first connect via the `psql` client:

```sh
docker exec -it postgresdb psql -U postgres
```

Then run:

```sql
CREATE DATABASE mastodon;
CREATE USER mastodon WITH ENCRYPTED PASSWORD 'your-password';
GRANT ALL PRIVILEGES ON DATABASE mastodon TO mastodon;
-- Above was apparently not enough to run DB migrations,
-- so this is needed too:
ALTER DATABASE mastodon OWNER TO mastodon;
```

### Nginx Config

Mastodon has an official recommended Nginx configuration
([see their repository](https://github.com/mastodon/mastodon/blob/v4.0.2/dist/nginx.conf)),
however I am hosting Mastodon inside a Docker container, and using Cloudflare, which makes
things more complicated.

<p class="info-bubble" markdown="1">
Make sure to check your HTTP caching headers (`Cache-Control`), and ensure
it plays well with Cloudflare 😉
</p>

Here's my `/etc/nginx/available-sites/social.alexn.org.conf` file:

```conf
upstream backend {
    server 127.0.0.1:3000 fail_timeout=0;
}

upstream streaming {
    server 127.0.0.1:4000 fail_timeout=0;
}

server {
    server_name social.alexn.org;
    listen   80;
    listen   [::]:80;

    access_log /var/log/nginx/social.alexn.org.log combined;

    location ~ /.well-known {
        root   /var/www/social.alexn.org;
        allow all;
        break;
    }

    location / {
        rewrite ^(.*)$ https://social.alexn.org$1 permanent;
    }
}

server {
    server_name social.alexn.org;
    listen 443 ssl;
    listen [::]:443 ssl;

    access_log /var/log/nginx/social.alexn.org.log combined;

    ###############
    # SSL

    # certs sent to the client in SERVER HELLO are concatenated in ssl_certificate
    ssl_certificate /etc/letsencrypt/live/alexn.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/alexn.org/privkey.pem;

    ## verify chain of trust of OCSP response using Root CA and Intermediate certs
    ssl_trusted_certificate /etc/letsencrypt/live/alexn.org/fullchain.pem;

    # Common config
    include ./snippets/ssl.conf;

    # END SSL
    ##############

    keepalive_timeout    70;
    sendfile             on;
    client_max_body_size 80m;

    root /var/www/social.alexn.org;
    include ./snippets/gzip.conf;

    location / {
        proxy_pass http://backend;
        include ./snippets/proxy-backend.conf;
    }

    location = /sw.js {
        proxy_pass http://backend;
        add_header Cache-Control "public, max-age=604800, must-revalidate";
        include ./snippets/proxy-backend.conf;
    }

    location ~ ^/system/ {
        proxy_pass http://backend;
        add_header Cache-Control "public, max-age=2419200, immutable";
        include ./snippets/proxy-backend.conf;
    }

    location ~ ^/(assets/|avatars/|emoji/|headers/|packs/|shortcuts/|sounds/) {
        proxy_pass http://backend;
        add_header Cache-Control "public, max-age=2419200, must-revalidate";
        include ./snippets/proxy-backend.conf;
    }

    location ^~ /api/v1/streaming {
        proxy_pass http://streaming;
        include ./snippets/proxy-streaming.conf;
    }

    error_page 500 501 502 503 504 /500.html;
}
```

Depends on this `./snippets/ssl.conf`:

```conf
###
# https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=intermediate&openssl=1.1.1k&guideline=5.6

ssl_session_timeout 1d;
ssl_session_cache shared:SSL:10m;  # about 40000 sessions
ssl_session_tickets off;

# Diffie-Hellman parameter for DHE ciphersuites, recommended 2048 bits
ssl_dhparam /etc/nginx/certs/dh2048.pem;

# intermediate configuration
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;

# HSTS (ngx_http_headers_module is required) (63072000 seconds)
add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";

# OCSP stapling
ssl_stapling on;
ssl_stapling_verify on;
```

Also, depends on `./snippets/proxy-backend.conf`:

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

Also, depends on `./snippets/proxy-streaming.conf`:

```conf
include ./snippets/cloudflare-ips.conf;

proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header Proxy "";

proxy_buffering off;
proxy_redirect off;
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection $connection_upgrade;
```

Also, depends on `./snippets/cloudflare-ips.conf`:

```conf
## Docs:
# https://support.cloudflare.com/hc/en-us/articles/200170786-Restoring-original-visitor-IPs-Logging-visitor-IP-addresses-with-mod-cloudflare-
#
# MUST KEEP UP TO DATE!

# https://www.cloudflare.com/ips-v4
set_real_ip_from 173.245.48.0/20;
set_real_ip_from 103.21.244.0/22;
set_real_ip_from 103.22.200.0/22;
set_real_ip_from 103.31.4.0/22;
set_real_ip_from 141.101.64.0/18;
set_real_ip_from 108.162.192.0/18;
set_real_ip_from 190.93.240.0/20;
set_real_ip_from 188.114.96.0/20;
set_real_ip_from 197.234.240.0/22;
set_real_ip_from 198.41.128.0/17;
set_real_ip_from 162.158.0.0/15;
set_real_ip_from 104.16.0.0/13;
set_real_ip_from 104.24.0.0/14;
set_real_ip_from 172.64.0.0/13;
set_real_ip_from 131.0.72.0/22;

# https://www.cloudflare.com/ips-v6
set_real_ip_from 2400:cb00::/32;
set_real_ip_from 2606:4700::/32;
set_real_ip_from 2803:f800::/32;
set_real_ip_from 2405:b500::/32;
set_real_ip_from 2405:8100::/32;
set_real_ip_from 2a06:98c0::/29;
set_real_ip_from 2c0f:f248::/32;

real_ip_header CF-Connecting-IP;
```

Also, depends on this `./snippets/gzip.conf`:

```conf
gzip on;
gzip_disable "msie6";

# Enable compression both for HTTP/1.0 and HTTP/1.1.
gzip_http_version  1.1;

# Compression level (1-9).
# 5 is a perfect compromise between size and cpu usage, offering about
# 75% reduction for most ascii files (almost identical to level 9).
gzip_comp_level    6;

# Don't compress anything that's already small and unlikely to shrink much
# if at all (the default is 20 bytes, which is bad as that usually leads to
# larger files after gzipping).
gzip_min_length    256;

# Compress data even for clients that are connecting to us via proxies,
# identified by the "Via" header (required for CloudFront).
gzip_proxied       any;

# Tell proxies to cache both the gzipped and regular version of a resource
# whenever the client's Accept-Encoding capabilities header varies;
# Avoids the issue where a non-gzip capable client (which is extremely rare
# today) would display gibberish if their proxy gave them the gzipped version.
gzip_vary          on;

# Sets the number and size of buffers used to compress a response.
# By default, the buffer size is equal to one memory page.
# This is either 4K or 8K, depending on a platform.
gzip_buffers	16 8k;

# Compress all output labeled with one of the following MIME-types.
gzip_types
	application/atom+xml
	application/font-woff
	application/javascript
	application/json
	application/rss+xml
	application/vnd.ms-fontobject
	application/x-font-ttf
	application/x-font-woff
	application/x-web-app-manifest+json
	application/xhtml+xml
	application/xml
	application/xml+rss
	font/opentype
	font/woff
	font/woff2
	image/svg+xml
	image/x-icon
	text/css
	text/javascript
	text/plain
	text/x-component
	text/xml;
```

### Backups

Script for periodically backing up Postgres via `rclone`, to install in `cron.d`:

```sh
#!/usr/bin/env bash

set -e

FILENAME="postgres-$(date +"%Y-%m").sql.gz"
FILEPATH="/var/lib/my-backups/$FILENAME"

mkdir -p /var/lib/my-backups

docker exec -i postgresdb pg_dumpall -U postgres | gzip > "$FILEPATH"

if [ -f "$FILEPATH" ]; then
  rclone copy "$FILEPATH" "backup:Postgres/"
fi

rm -f /var/lib/my-backups/postgres-*.sql.gz
```

Script for periodically backing up your media files (but without the cache),
via `rclone`, to install in `cron.d`:

```sh
#!/usr/bin/env bash

set -e

FILENAME="mastodon-volume.tar"
FILEPATH="/var/lib/my-backups/$FILENAME"

docker run \
    --rm \
    --volumes-from mastodon-web \
    -v /var/lib/my-backups:/backup \
    ubuntu \
    tar --exclude='mastodon/public/system/cache' -cf "/backup/$FILENAME" -C / "mastodon/public/system" \
    2>&1

if [ -f "$FILEPATH" ]; then
  rclone copy "$FILEPATH" "backup:Mastodon/"
  rm -f "$FILEPATH"
fi
```

<p class="warn-bubble" markdown="1">
There may be better ways of doing this (like simply using block storage),
I'm still learning.
</p>
