---
title: "Matomo (Analytics) Hosting via Docker"
date: 2021-02-22 00:12:25+0200
tags:
  - Blogging
  - Self-hosting
  - Web
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