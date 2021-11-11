---
date: 2020-08-24 16:24:31+0300
title: "Docker"
---

## Installation

### MacOS

`brew cask install docker`

## Basic usage

### Running a container interactively

Pulling an existing from the repository:

``` sh
docker pull nats:latest
```

Then to run this image in a container:

``` sh
docker run -p 4222:4222 -ti nats:latest
```

Params used:

- `-p`: publishes a container's port (a mapping from container to host)
- `-i`: keep STDIN open even if not attached — this means `<cmd> | docker run` works
- `-t`: allocates a pseudo-TTY, which in combination with `-i` means we can interact with the process

### Running a container as daemon

For this we add the `-d` option:

``` sh
docker run -p 4222:4222 -d -ti nats:latest
```

### List containers

List active containers:

```sh
docker ps --no-trunc
```

List all containers:

```sh
docker ps -a
```

### Start & stop containers

Stops container with the id `<containerid>`:

```sh
docker stop <containerid>
```

Stops all running containers:

```sh
docker stop $(docker ps -a -q)
```

To re-start a certain container:

```sh
docker start <containerid>
```

### Remove containers

``` sh
docker rm <container_id>
```

Remove all containers:

```sh
docker rm $(docker ps -a -q)
```

If some containers are still running as a daemon, use `-f` (force):

```sh
docker rm -f $(docker ps -a -q)
```

### Remove orphan volumes

List:

``` sh
docker volume ls -qf dangling=true
```

Remove:

``` sh
docker volume rm $(docker volume ls -qf dangling=true)
```

### List or remove images

List images available locally:

``` sh
docker images
```

Remove all images:

``` sh
docker rmi $(docker images -q -a)
```

### List or remove volumes

```sh
docker volume ls
```

To remove:

```sh
docker volume rm <id>
```

Remove all volumes:

```sh
docker volume rm $(docker volume ls -q)
```

### Gain shell access to a container

``` sh
docker exec -it <container_id> sh
```

### Clean Restart of all Docker Instances

```sh
# Stop all containers
docker-compose down

# Delete all containers
docker rm -f $(docker ps -a -q)

# Delete all volumes
docker volume rm $(docker volume ls -q)

# Restart all containers
docker-compose up -d
```

## Building Docker images

Resources:

- [Dockerizing a Node.js web app](https://nodejs.org/en/docs/guides/nodejs-docker-webapp/)


## Auto-update containers to latest

Run watchtower container, with option to auto update only labelled containers:

``` sh
docker run -d \
  --restart=always \
  --name=watchtower \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --label-enable
```

If using `docker-compose`:

``` yml
watchtower:
  container_name: watchtower
  image: 'containrrr/watchtower:latest'
  restart: unless-stopped
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
  restart: unless-stopped
  networks:
    - main
  command: --label-enable
```

To mark images for auto-updating:

``` sh
docker run -d --label=com.centurylinklabs.watchtower.enable=true someimage
```

Or if using `docker-compose`:

```yaml
version: '3'

services:
  app:
    image: 'someimage'
    restart: always
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
```

Watchtower will check periodically for newer images and will restart services/containers with new image.

## Docker Compose

See [docs for installing](https://docs.docker.com/compose/install/).

``` sh
brew install docker-compose
```

Given a [docker-compose.yml](https://docs.docker.com/compose/) in the current directory, starting all containers:

``` sh
docker-compose up
```

Or to start them as a daemons (in the background):

``` sh
docker-compose up -d
```

### Example docker-compose.yml

``` yml
version: "3.7"

services:
  nats:
    image: nats-streaming:latest
    entrypoint:
    - /nats-streaming-server
    - -cid
    - amethyst-cluster
    ports:
    - "4222:4222"
    - "8222:8222"
    - "6222:6222"
    restart: always
    tty: true
    networks:
      - main

  mysql:
    image: mysql:8.0
    ports:
      - "3306:3306"
    restart: always
    tty: true
    environment:
      MYSQL_DATABASE: mydb
      MYSQL_USER: myuser
      MYSQL_PASSWORD: mypass
      MYSQL_ROOT_PASSWORD: root
    volumes:
      - db-data:/var/lib/mysql
    networks:
      - main

  redis:
    image: redis:latest
    ports:
      - "6379:6379"
    restart: always
    tty: true
    networks:
      - main

  myimage:
    image: myorganization/myimage:latest
    build: .
    depends_on:
      - nats
      - mysql
      - redis
    environment:
      ENV: stage
      LANG: C.UTF-8
      NATS_SERVERS: "nats://nats:4222"
      VOLUME_PATH: "/tmp/dont_care"
    networks:
      - main
    command: bash /path/to/custom-command.sh
    volumes:
      - .:/tmp/dont_care

volumes:
  db-data:

networks:
  main:
    external:
      name: main
```
