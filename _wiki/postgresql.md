---
date: 2020-08-24 16:24:31+0300
title: "PostgreSQL"
---

## Creating new database and user

```sql
CREATE DATABASE yourdbname;
CREATE USER youruser WITH ENCRYPTED PASSWORD 'yourpass';
GRANT ALL PRIVILEGES ON DATABASE yourdbname TO youruser;
```
