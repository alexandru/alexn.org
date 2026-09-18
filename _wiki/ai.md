---
date: 2026-08-17 08:17:23 +03:00
last_modified_at: 2026-08-30 11:09:01 +0300
---

# AI/LLM

## Agent Harnesses

- [Copilot CLI](https://github.com/features/copilot/cli)
- [OpenCode](https://opencode.ai/)
- [Pi](https://pi.dev/)

## Configurations

Mine:

- [opencode-config](https://github.com/alexandru/opencode-config)
- [copilot-cli-config](github.com/alexandru/copilot-cli-config)
- [agents-config](https://github.com/alexandru/agents-config)

## Skills repositories

- [alexandru/skills](https://github.com/alexandru/skills)
- [mattpocock/skills](https://github.com/mattpocock/skills)

## Tooling

### Cellar: query the public API of any Maven JVM dependency

Repository: [VirtusLab/cellar](https://github.com/VirtusLab/cellar)

Installing the skill:
```
npx skills add https://github.com/VirtusLab/cellar/ -y 
```

### Tokscale: Track tokens usage across sessions

With [Tokscale](https://github.com/junhoyeo/tokscale):

```
npx tokscale@latest \
    --client opencode \
    --since 2026-08-17 \
    --until 2026-08-17
```
