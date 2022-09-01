---
date: 2020-08-24 16:24:31 +03:00
last_modified_at: 2022-09-01 17:24:09 +03:00
---

# MySQL / MariaDB

## Start a Docker Instance

```sh
docker run --rm --name mariadb -e MYSQL_ROOT_PASSWORD=pass -p 3306:3306 mariadb:10.5 
```

Note `--rm` deletes the container after stop. Also add `-d` to detach (daemon mode).

To connect to it:

```sh
docker exec -it mariadb mysql -uroot -ppass
```

## Create user

``` sql
CREATE USER 'myuser'@'%' IDENTIFIED BY 'password';

GRANT ALL PRIVILEGES ON mydatabase.* TO 'myuser'@'%';
```

Note: `localhost` used as the host only allows access from `localhost`, whereas `%` allows access from everywhere.

## Create Database

After 8.0:

``` sql
CREATE DATABASE mydatabase CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
```

Before 8.0:

``` sql
CREATE DATABASE mydatabase CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

Version 5.7:

``` sql
CREATE DATABASE mydatabase CHARACTER SET utf8 COLLATE utf8_general_ci;
```
