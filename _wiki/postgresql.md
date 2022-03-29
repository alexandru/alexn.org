---
title: "PostgreSQL"
date: 2020-08-24 16:24:31 +03:00
last_modified_at: 2022-03-29 10:43:54 +03:00
---

## Creating new database and user

```sql
CREATE DATABASE yourdbname;
CREATE USER youruser WITH ENCRYPTED PASSWORD 'yourpass';
GRANT ALL PRIVILEGES ON DATABASE yourdbname TO youruser;
```
