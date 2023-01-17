---
title: "Matomo (Analytics) Hosting via Docker"
tags:
  - Blogging
  - SelfHosting
  - Web
feed_guid: /snippets/2021/02/22/matomo-hosting-via-docker/
redirect_from:
  - /snippets/2021/02/22/matomo-hosting-via-docker/
  - /snippets/2021/02/22/matomo-hosting-via-docker.html
description: >
  Docker setup for self-hosting Matomo, an open-source alternative to Google Analytics.
last_modified_at: 2023-01-17 14:42:55 +02:00
---

For self-hosting [Matomo](https://matomo.org/), a FOSS alternative to Google Analytics — via [docker-compose](https://docs.docker.com/compose/):

```yaml
version: '3.3'

services:
  db:
    container_name: mariadb
    image: mariadb:10.5
    ports:
      - "3306:3306"
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    command: --max-allowed-packet=64MB
    restart: unless-stopped
    volumes:
      - db:/var/lib/mysql
    env_file:
      - ./envs/mysql.env
    networks:
      - main
  
  redis:
    container_name: redis
    image: redis:6-alpine
    restart: unless-stopped
    command: redis-server --appendonly yes
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    volumes:
      - redis:/data
    networks:
      - main
    sysctls: # https://github.com/docker-library/redis/issues/191#issuecomment-528693994
      - net.core.somaxconn=511
        
  matomo:
    container_name: matomo
    image: matomo:4-fpm-alpine
    links:
      - db
      - redis
    restart: unless-stopped
    expose: 
      - "9000"
    ports:
      - "9000:9000"
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    volumes:
      - /var/www/matomo:/var/www/html
    networks:
      - main
    environment:
      - MATOMO_DATABASE_HOST=db
    env_file:
      - ./envs/mysql.env
      - ./envs/matomo.env
    user: "$WWW_UID:$WWW_GID"
    
networks:
  main:
    external:
      name: main

volumes:
  db:
  redis:
```