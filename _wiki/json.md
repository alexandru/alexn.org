---
date: 2020-08-24 16:24:31 +03:00
last_modified_at: 2022-09-01 17:23:41 +03:00
---

# JSON

## Command-line parsing

[jq](https://stedolan.github.io/jq/) — command-line JSON processor.

Sorting in descending order by field:

```bash
bw list items | jq 'sort_by(.revisionDate)|reverse'
```

Tutorial:
- [Handle large JSONs effortlessly with jq](https://leonid.shevtsov.me/post/handle-large-jsons-effortlessly-with-jq/)
