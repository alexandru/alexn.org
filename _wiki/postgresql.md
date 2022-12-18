---
date: 2020-08-24 16:24:31 +03:00
last_modified_at: 2022-12-18 16:15:52 +02:00
---

# PostgreSQL

## Creating new database and user

Open the client:

```sh
psql -U postgres
```

Execute:

```sql
CREATE DATABASE yourdbname;
CREATE USER youruser WITH ENCRYPTED PASSWORD 'yourpass';
GRANT ALL PRIVILEGES ON DATABASE yourdbname TO youruser;
ALTER DATABASE yourdbname OWNER TO youruser;
```

## Running in a Docker container

Setup for `docker-compose.yaml`:

```yaml
services:
  postgresdb:
    container_name: postgresdb
    image: 'postgres:15-alpine'
    volumes:
      - 'postgres-db:/var/lib/postgresql/data'
    restart: unless-stopped
    env_file:
      - ./envs/postgres.env
    networks:
      - main

networks:
  main:
    name: main

volumes:
  postgres-db:
```

Where `./envs/postgres.env`:

```sh
POSTGRES_PASSWORD="your-admin-password"
```
