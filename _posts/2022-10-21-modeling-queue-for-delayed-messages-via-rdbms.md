---
title: "Building a Queue for Delayed Messages via a RDBMS (1): Design"
image: /assets/media/articles/2022-delayed-queue-design.png
date: 2022-10-21 09:46:07 +03:00
last_modified_at: 2023-05-28 09:39:22 +03:00
generate_toc: true
tags:
  - SQL
social_description: "Scheduling messages in the future, when your MQ isn't up to the task."
description: >
  Ever had the need to deliver messages on your queue at a certain timestamp in the future? Look no further, because your RDBMS can do it. This is part 1 of a series that builds a solution from scratch.
---

<p class="intro">
Ever had the need to deliver messages on your queue at a certain timestamp in the future? Look no further, because your RDBMS can do it. This is part 1 of a series that builds a solution from scratch.
</p>

In our $work project we had the need to push messages on a queue, but delayed, for delivery at a certain timestamp in the future. Our existing MQ servers aren't adequate for that, and we can't introduce more technology in our stack.

Turns out, a relational database is perfectly adequate (such as MySQL or PostgreSQL). Here's how...

First, establish the requirements:

- Multiple consumers can read from the queue, at the same time, however only one consumer can gain access to a message for processing;
- When a consumer pulls a message from the queue, that message becomes invisible for other consumers — but if, after a timeout, the consumer fails to process the message and then "acknowledge" that the processing is done (commit), then the message becomes visible again for other consumers (standard MQ functionality);
- We need a message key, such that we can avoid duplicate messages (functionality usually not provided by standard queues);
- The payload is usually JSON, but the datatype should be encoded in the table row, such that we know how to parse it, also doubling as an extra validation;

## Run-loop

Your code should look more or less like this pseudocode, you can insert your favorite libraries and abstractions, as this could be built via reactive streams or what not:

```kotlin
while (true) {
  val message = selectNextMessageAvailable()
  if (message == null) {
    sleep(15.seconds)
    continue // next please
  }

  val lockAcquired = updateAcquireLock(message)
  if (!lockAcquired) {
    continue // next please
  }

  try {
    // do whatever it is we want with our message
    process(message)
    // if everything went well, mark it as processed
    delete(message)
  } catch (e: Exception) {
    logger.error(e)
  }
}
```

## Creating the table

The RDBMS table might look like the following — note we are using MySQL/MariaDB as our chosen dialect:

```sql
CREATE TABLE DelayedQueue
(
    pKey VARCHAR(200) NOT NULL,
    pKind VARCHAR(100) NOT NULL,
    payload BLOB NOT NULL,
    scheduledAt BIGINT NOT NULL,
    scheduledAtInitially BIGINT NOT NULL,
    createdAt BIGINT NOT NULL,
    PRIMARY KEY (pKey, pKind)
);

CREATE INDEX DelayedQueue__KindPlusScheduledAtIndex
ON DelayedQueue (pKind, scheduledAt);
```

Thus, we have these fields:

- The primary key is the tuple `(pKey, pKind)` — the `pKey` can uniquely identify the message, but `pKind` is needed to indicate the stored data type, as we need to validate that we can parse it;
- The `payload` can be our JSON document;
- `scheduledAt` is a Unix timestamp (in seconds) indicating when the message is scheduled for delivery — note that this gets used in the `SELECT`, but also doubles as the "lock" we acquire on messages that are in processing, being `UPDATED` on each pull — which is why we also need `scheduledAtInitially`, meant for debugging;

## Pushing new messages

Pushing messages for new keys is easy:

```sql
INSERT IGNORE INTO DelayedQueue
  (pKey, pKind, payload, scheduledAt, scheduledAtInitially, createdAt)
VALUES (
  "c71de6b4-510f-11ed-9d4d-0242ac120002",
  'Contact',
  '{ "name": "Alex", "emailAddress": "noreply@alexn.org" }',
  UNIX_TIMESTAMP('2022-10-22 10:00:00'),
  UNIX_TIMESTAMP('2022-10-22 10:00:00'),
  UNIX_TIMESTAMP() -- now
);
```

Note, I am using `INSERT IGNORE`, because we may deal with duplicates. MySQL/MariaDB allows us to do that, which is pretty nice. Some databases don't have this syntax, and in Java, primary key violations turn into exceptions. Pattern matching `java.sql.SQLException` is something that should be avoided at all costs, as the error you get depends on the database vendor and the context, and you need to find those by trial and error. For example, for Microsoft's SQL Server, you have to look for [error code 2627](https://docs.microsoft.com/en-us/sql/relational-databases/replication/mssql-eng002627), or [error code 2601](https://docs.microsoft.com/en-us/sql/relational-databases/replication/mssql-eng002601), possibly in combination with sql state `23000`. Whereas for HSQLDB, you have to look for error code `-104` in combination with sql state `23505`.

## Polling the queue

We do a `SELECT` to see if there are any messages where `scheduledAt <= NOW`.

And for as long as there are no messages available, we repeat the query after a configurable delay. The time interval depends on your latency requirements, but for delayed messages this is not an issue, so you could repeat the query every 15 seconds or so. Repeating it more often could have a negative impact on the database, so be careful with this configuration.

```sql
SELECT
  pKey, payload, scheduledAt, createdAt
FROM DelayedQueue
WHERE
  pKind = 'Contact' AND scheduledAt <= UNIX_TIMESTAMP()
ORDER BY scheduledAt
LIMIT 1;
```

Note that this query is optimized by the index that we already created.

## Acquiring the lock

Once we have a message available, we have to make it invisible for other consumer, such that there is at most one consumer processing it at the same time. So we need a "lock" per message.

```sql
UPDATE DelayedQueue
SET
  -- acquires the lock, sets the timeout in 5 minutes
  scheduledAt = UNIX_TIMESTAMP() + 60 * 5
WHERE
  pKey = 'c71de6b4-510f-11ed-9d4d-0242ac120002' AND
  pKind = 'Contact' AND
  scheduledAt = 1666422000 -- concurrency check ;-)
;
```

Whatever database client you're using (e.g., JDBC), it will return the number of updated rows. If the update suceeds, it should return `1`, if the update fails (due to another consumer winning this race), then it should return `0`. If `updatedRows > 0`, then you have successfully acquired the lock on this message, otherwise, you cannot proceed, instead you need to retry the transaction (SELECT + UPDATE).

<p class="info-bubble" markdown="1">
NOTE: `scheduledAt` is updated to be in the future. THIS here is what makes it invisible to other consumers, with a 5 minutes timeout (after which it becomes visible again).
</p>

## Transactional commit (acknowledge)

Once a consumer processes the message, it needs to be marked as being processed. We can do that by deletion, but we need to be careful:

```sql
DELETE FROM DelayedQueue
WHERE
  pKey = 'c71de6b4-510f-11ed-9d4d-0242ac120002' AND
  pKind = 'Contact' AND
  -- Race-condition check (1) — value should be set from user code:
  createdAt = 1666340050 AND
  -- Race-condition check (2) — value should be set from user code:
  scheduledAt = 1666422300
;
```

We can't just delete anything that has that key, because:

1. The initial timeout might have passed, and we might now have a concurrent execution (which is inevitable);
2. We might have a new key that was reused;

As such, we need to check the combination of `createdAt` (to check that we still have the same entry, instead of a new one), and our updated `scheduledAt` (to ensure that we are not dealing with a concurrent execution after timeout).

## Coming up next ...

I'm going to follow up with an article that actually builds this, as a Java/Scala/Kotlin library.
