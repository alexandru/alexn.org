---
title: "Personal Server Backups"
image: /assets/media/articles/2022-backup-vps.png
# image_caption:
date: 2022-12-02 19:56:39 +02:00
last_modified_at: 2023-01-17 13:17:59 +02:00
generate_toc: true
tags:
  - Self-hosting
  - Server
  - Shell
  - Web
---

<p class="intro withcap" markdown="1">
Cloud hosting services like Linode or DigitalOcean offer backup services for your VPS. Save your money, you don't need it. Here's how to backup your data safely, and with no extra costs...
</p>

The plan, for your inspiration:

1. Place all your server configuration in a personal git repository;
2. Backup your data via cron jobs, with the help of [rclone](https://rclone.org/);
3. Test how reliable recovery is every time you update your server to a major Linux distribution version;

## Server configuration

On my server, I use the latest LTS of Ubuntu Linux, since it's what I've grown accustomed to. I have a personal GitHub repository where I store the server's configuration. The bulk of it is:

1. A [docker-compose.yaml](https://docs.docker.com/compose/) file;
2. Nginx configurations for my domains;
3. Scripts that need to execute periodically via `cron.d`;
4. A `setup.sh` script that configures a server from scratch.

One of these days I'll try [NixOS](https://nixos.org/), as a lot of people love it, and it's designed for precisely this use-case: to have a reproducible environment described by configuration kept in a repository.

Start small, and think big. Can you reconfigure a server from scratch in less than an hour? If not, why not?

## Rclone backups via cron jobs

You can use Dropbox for storing your backups, you can use Amazon's S3, or as a pretty cheap alternative, you can use [Backblaze B2](https://www.backblaze.com/b2/cloud-storage.html). I use Dropbox, since I'm paying for a Plus account anyway, and I have a lot of unused space. Dropbox also keeps about 1-month worth of [version history](https://help.dropbox.com/delete-restore/version-history-overview), so it's decent.

The [Rclone](https://rclone.org/) utility supports a lot of backends, including the aforementioned ones.

<p class="warn-bubble" markdown="1">
**WARNING:** when configuring `rclone` on your server, you need to think about security. If you have important personal data in your cloud storage, you don't want to give attackers access to it. Which is why a separation would be better. I used Dropbox because I could set it up such that access is restricted to an "app folder" ([see their docs](https://www.dropbox.com/developers/reference/getting-started) for configuring your own "app"). If you can't do that, it would be safer to create another account (e.g., Backblaze B2), and give access to buckets that are only used for these backups.
</p>

The "remote" that I configure (via `rclone config`) has the name `backup`, which are then used in the following scripts.

For your inspiration, as a sample, here's the script for backing up my MariaDB / MySQL database (named `vm-backup-mysql`). Note that the database is in a Docker container, and we also need a `mysql.env` file somewhere with the root password:

```sh
#!/usr/bin/env bash

set -e

DIR="$(dirname "$0")"
set -o allexport; source "$DIR/../docker/envs/mysql.env"; set +o allexport

FILENAME="mysql-$(date +"%Y-%m").sql.gz"
FILEPATH="/var/lib/my-backups/$FILENAME"

mkdir -p /var/lib/my-backups

docker exec -i mariadb /bin/mysqldump -u root \
  "-p$MYSQL_ROOT_PASSWORD" \
  --lock-tables=false \
  --all-databases | gzip > "$FILEPATH"

if [ -f "$FILEPATH" ]; then
  rclone copy "$FILEPATH" "backup:MySQL/"
fi

rm -f /var/lib/my-backups/mysql-*.sql.gz
```

Here's the script for backing up the data for my [Isso comments service](https://github.com/posativ/isso/), named `vm-backup-isso`. This script is backing up the configuration (from `/etc/isso`) and the SQLite database (from `/var/lib/isso`):

```sh
#!/usr/bin/env bash

set -e

FILENAME1="isso-db-$(date +"%Y-%m").tar.gz"
FILEPATH1="/var/lib/my-backups/$FILENAME1"
FILENAME2="isso-cfg.tar.gz"
FILEPATH2="/var/lib/my-backups/$FILENAME2"

mkdir -p /var/lib/my-backups
cd /var/lib/my-backups || exit 1

tar cvzf ./"$FILENAME1" -C / var/lib/isso 
tar cvzf ./"$FILENAME2" -C / etc/isso 

if [ -f "$FILEPATH1" ]; then
  rclone copy "$FILEPATH1" "backup:Isso/"
fi

if [ -f "$FILEPATH2" ]; then
  rclone copy "$FILEPATH2" "backup:Isso/"
fi

rm -f /var/lib/my-backups/isso-*.tar.gz
```

Here's the script for backing up my [FreshRSS](https://freshrss.org/) [OPML file](https://en.wikipedia.org//wiki/OPML), such that I never lose my blog subscriptions 🙂

```sh
#!/bin/bash

set -e

FILENAME="freshrss-$(date +"%Y-%m").opml.xml.gz"
FILEPATH="/var/lib/my-backups/$FILENAME"

if [ $(docker inspect -f '{% raw %}{{.State.Running}}{% endraw %}' freshrss) ]; then
  echo "[$(date +"%Y-%m-%d %H:%M:%S%z")] Generating $FILEPATH"
  docker exec -t freshrss /bin/bash -c -i "/var/www/FreshRSS/cli/export-opml-for-user.php --user alexandru 2>/dev/null" | gzip >"$FILEPATH"

  if [ -f "$FILEPATH" ]; then
    rclone copy "$FILEPATH" "backup:FreshRSS/"
  fi
fi

rm -f /var/lib/my-backups/freshrss-*.gz
```

Finally, here's my [cron setup](https://en.wikipedia.org/wiki/Cron), in a file named `/etc/cron.d/vm-cron`:

```sh
MAILTO=cron-errors@my.address.com

# ----------------
# Backups

10 */6 * * * root  cronic /opt/vm/bin/vm-backup-mysql
20 */6 * * * root  cronic /opt/vm/bin/vm-backup-isso
30 */6 * * * root  cronic /opt/vm/bin/vm-backup-freshrss
```

As you can see, backups are running on my VPS every 6 hours. I have more fine-grained backups than what services like Linode or DigitalOcean can provide.

<p class="warn-bubble" markdown="1">
**WARNING:** when doing backups, it's best if you have a system alterting you when something goes wrong, like when `rclone` can no longer connect to your remote. Which is why sending emails on error is a good practice.
</p>

My server is configured to send emails via Fastmail, as an external `relayhost`. See [my wiki entry]({% link _wiki/ubuntu-server.md %}#configure-sending-emails-via-fastmail-or-another-smtp-server) for details on the setup. In the cron setup above, I'm using [cronic](https://habilis.net/cronic/), a small utility that silences the output of those scripts, only outputting to stdout and stderr if the script finishes with an error code. The effect is that the cron service will only send emails when errors happen.

## Test your backups

You won't know that you have working backups, unless you test them periodically.

For me this happens naturally, because I'm staying on Ubuntu LTS releases, and frankly updating major Ubuntu versions is best done from scratch. And I also keep resizing my VPS. This means that I frequently recreate my VPS from scratch.

Nowadays, I can do it in about 1 hour, with no access to the previous VPS setup, as everything I need is already in GitHub or in Dropbox. The more you automate, and the more you test that automation, the more reliable it is when you'll actually need it.
