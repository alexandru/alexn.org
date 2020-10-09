---
date: 2020-08-24 16:24:31+0300
---

# GitHub 

## Tools

- For creating labels: <https://github.com/integratedexperts/github-labels/>

## Trigger manual build

We can use GitHub's API to trigger a custom event, e.g:

```
curl --fail \
  -XPOST -u "${GH_USERNAME}:${GH_TOKEN}" \
  -H "Accept: application/vnd.github.everest-preview+json" \
  -H "Content-Type: application/json" \
  https://api.github.com/repos/${REPO_ORGANIZATION}/${REPO_NAME}/dispatches \
  --data '{"event_type": "custom_event"}'
```

Set the `GH_USERNAME`, `GH_TOKEN`, `REPO_ORGANIZATION` and `REPO_NAME` environment variables. Might also want to set the `custom_event` identifier to something that makes sense for you.

Then in GitHub Actions to trigger an action in response to this `custom_event`:

```yaml
on:
  repository_dispatch:
    types: [custom_event]
```
