# MySQL / MariaDB

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
