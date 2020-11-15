---
title: "Saving JSON in Relational Databases"
tags:
  - Code
  - FP
  - Doobie
  - Scala
---

The database migration we need:

```sql
CREATE TABLE VesperKeyValueStore
(
    `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `uKey` varchar(200) NOT NULL,
    `uKind` varchar(50) NOT NULL,
    `version` BIGINT NOT NULL,
    `payload` TEXT NOT NULL,
    `createdAt` TIMESTAMP NOT NULL,
    `updatedAt` TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX VesperKeyValueStore__UserKey
ON VesperKeyValueStore(uKey, uKind);

CREATE UNIQUE INDEX VesperKeyValueStore__VersionIndex
ON VesperKeyValueStore(uKey, uKind, version);

CREATE INDEX VesperKeyValueStore__KindListIndex
ON VesperKeyValueStore(uKind, id);
```

Translating this to other database implementations is easy enough, as we are using no special MySQL 


