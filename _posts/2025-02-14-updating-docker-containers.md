---
title: "Auto-updating Docker containers"
date: 2025-02-14T07:00:00+02:00
last_modified_at: 2025-02-14T15:01:58+02:00
tags:
  - Docker
  - Self Hosting
  - Server
description: >
  I'm self-hosting stuff using Docker on my own server. One problem that comes up for a personal server is to keep it up to date, as old software has security issues. And we don't want to self-host servers that can become vulnerable due to neglect.
---

<p class="intro">
  I'm self-hosting stuff using Docker on my own server. One problem that comes up for a personal server is to keep it up to date, as old software has security issues. And we don't want to self-host servers that can become vulnerable due to neglect.
</p>

There are a bunch of solutions floating around, but for a personal server, the most pragmatic solution I found is a simple script:

```bash
#!/usr/bin/env bash
set -e

cd "$(dirname "$0")" || exit 1
BINDIR="$(pwd)"
SC='\033[0;36m' # Cyan (0;36)
NC='\033[0m' # No Color

printf "${SC}------------------------------------------------${NC}\n"
printf "${SC}Updating & Cleaning Docker — $(date +"%Y-%m-%d %H:%M:%S %Z")${NC}\n"
printf "${SC}------------------------------------------------${NC}\n"

printf "\n${SC}> docker image prune -af${NC}\n\n"
docker image prune -af  2>&1

printf "\n${SC}> docker images | grep -v REPOSITORY | awk '{print \$1\":\"\$2}' | xargs -Iname docker pull name${NC}\n\n"
docker images | grep -v REPOSITORY | awk '{print $1":"$2}' | xargs -Iname docker pull --quiet name 2>&1

printf "\n${SC}> docker compose up -d --remove-orphans${NC}\n\n"
docker compose up -d --remove-orphans  2>&1

printf "\n${SC}> docker image prune -af${NC}\n\n"
docker image prune -af  2>&1

printf "\n${SC}> docker system prune -f${NC}\n\n"
docker system prune -f  2>&1
```

You can then add this to `/etc/cron.d/` to run once per day:

```cron
0 3 * * * root cronic /path/to/bin/vm-docker-update-all
```

Note that I'm using [cronic](https://habilis.net/cronic/) for getting alerted over email when my cron scripts are failing. You can ignore that part.

The astute reader will wonder — doesn't this aggressive policy have the potential to break your setup? Upgrades for docker images, especially `latest` images, aren't necessarily security upgrades. So the answer is: of course, new versions can break backwards compatibility with your current setup (e.g., database schemas), but I'd rather have a broken server than a vulnerable one. And I think the only problem I encountered thus far was when my [Mastodon instance](https://social.alexn.org/) was automatically upgraded from 4.2.x to 4.3.x, but then I quickly got an email from my [Monit instance](./2023-01-17-server-monitoring-with-monit.md).

With upgrade policies in place, health monitoring and [backups](./2022-12-02-personal-server-backups.md), self-hosting stuff is cheap and joyful.
