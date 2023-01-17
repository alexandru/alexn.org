---
title: "Server Monitoring with Monit"
image: /assets/media/articles/2023-monit-panel.png
image_caption: >
  A screenshot of my browser window, showing the 3 monitors that I configured in Monit, all green-lit, indicating that everything is fine.
image_hide_in_post: true
date: 2023-01-17 13:16:12 +02:00
last_modified_at: 2023-01-17 14:21:36 +02:00
tags:
  - Docker
  - Self-hosting
  - Shell
  - Snippet
social_description: >
  How I now monitor my personal server (hosting my blog, other websites, Matomo, Mastodon, etc.).
---

<p class="intro withcap" markdown=1>
  I self-host my blog, other websites, [Matomo](https://matomo.org/), [Mastodon](https://joinmastodon.org/), etc. I love self-hosting. But I need monitoring, to be alerted when things go wrong, as my setup is getting more and more complex. So, I recently asked a [question on the Fediverse](https://social.alexn.org/@alexelcu/109658239137618383), being in need of a monitoring system for my VPS, as I need simple, common-sense health alerts. I got a recommendation for [M/Monit](https://mmonit.com/), which seems to work well.
</p>

Even though I use Docker, I decided to install it at the OS level. Given I use Ubuntu on my server, this is as simple as:

```sh
apt install monit
```

Its configuration (in `/etc/monit/conf.d/my.conf`) looks like this:

```yaml
# Monit configuration

## ----
## Configures server port (proxied via Nginx)
set httpd 
    port 2812
        read-only
    unixsocket /run/monit.socket
    allow localhost
    allow monit.alexn.org
    signature disable

## Configures email alerts
set mailserver localhost
set alert user@domain.com not on { instance, action } with reminder on 500 cycles

## Monitors system load
check system $HOST
    if loadavg (1min) per core > 2 for 5 cycles then alert
    if loadavg (5min) per core > 1.5 for 10 cycles then alert
    if cpu usage > 95% for 10 cycles then alert
    if memory usage > 90% then alert
    if swap usage > 25% then alert

## Monitors file-system
check filesystem rootfs with path /
    if space usage > 80% for 5 times within 15 cycles then alert
    if inode usage > 80% for 5 times within 15 cycles then alert

## Monitors Docker instances
check program docker-health with path /opt/bin/vm-docker-check-health
    with timeout 10 seconds
    if status != 0 then alert
```

My hostname is `monit.alexn.org` for exposing the HTTP interfaces. I decided for a read-only interface. It's less to worry about, and I don't need a remote control. I use Nginx as a proxy:

```conf
server {
    server_name monit.alexn.org;
    listen   80;
    listen   [::]:80;
    access_log /var/log/nginx/monit.alexn.org.log combined;

    location / {
        rewrite ^(.*)$ https://monit.alexn.org$1 permanent;
    }
}

server {
    server_name monit.alexn.org;
    listen 443 ssl;
    listen [::]:443 ssl;

    access_log /var/log/nginx/monit.alexn.org.log combined;

    # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=intermediate&openssl=1.1.1k&guideline=5.6
    ssl_certificate /etc/letsencrypt/live/alexn.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/alexn.org/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/alexn.org/fullchain.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;  # about 40000 sessions
    ssl_session_tickets off;
    ssl_dhparam /etc/nginx/certs/dh2048.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";
    ssl_stapling on;
    ssl_stapling_verify on;

    location / {
        root   /var/www/monit.alexn.org;
        auth_basic "Monit";
        auth_basic_user_file /etc/secrets/auth/monit-htpasswd; 

        proxy_pass http://0.0.0.0:2812;
        proxy_set_header Host $host;
        proxy_connect_timeout 300;
    }
}
```

Generating a "htpasswd" file can be accomplished with this command:

```sh
htpasswd -B -c etc/secrets/auth/monit-htpasswd yourUserName
```

That configuration alerts me on 3 things:

1. The system's load (CPU, RAM, Swap);
2. The available disk space;
3. The health of my Docker containers;

For checking the Docker containers, I have a simple script that's configured above to be executed periodically:

```sh
#!/usr/bin/env bash

UNHEALTHY_IDS="$(docker ps -q \
    -f health="none" \
    -f health="unhealthy" \
    -f status="exited" \
    -f status="dead" \
    -f status="paused" \
    )"

if [[ -z "$UNHEALTHY_IDS" ]]; then
    docker ps --format "table {{.Names}}\t{{.Status}}"
    exit 0
fi

echo >&2
echo "WARN: Unhealthy docker instances!" >&2
echo "---------------------------------" >&2
docker ps --format "table {{.Names}}\t{{.State}}\t{{.Status}}" \
    -f health="none" \
    -f health="unhealthy" \
    -f status="exited" \
    -f status="dead" \
    -f status="paused" >&2
exit 1
```

<p class="warn-bubble" markdown="1">
  WARN: you need an email server configured for receiving those alerts!
</p>

You need to configure Monit with an email server. I just use my `localhost` because I can configure `postfix` to use my Fastmail account as a relay. **See my [Ubuntu wiki page](../_wiki/ubuntu-server.md)** for details on how to do that.

After all is well, here's how my status panel looks like:

<figure>
  <img src="{% link assets/media/articles/2023-monit-panel.png %}" alt="" />
  <figcaption>A screenshot of my browser window, showing the 3 monitors that I configured in Monit, all green-lit, indicating that everything is fine.</figcaption>
</figure>

Now I can sleep well at night 🥱
