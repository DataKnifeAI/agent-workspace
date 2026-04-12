# agent-workspace

Starting **git workspace** for [Cursor Cloud Agents](https://cursor.com/docs/cloud-agent): clone this repository (or fork it) as the base repo cloud agents use for branches, hooks, and shared tooling.

## Cloud agents

- Cloud agents clone your repository and work on a separate branch; you need read/write access to this repo and any **submodules** it references. See [Cloud Agents](https://cursor.com/docs/cloud-agent).
- [Self-Hosted Pool](https://cursor.com/docs/cloud-agent/self-hosted-pool) workers run from a checked-out copy of the repo; project skills under `.cursor/skills/` (or `.agents/skills/`) are available on workers.

## Shared skills (submodule)

This repo includes the [DataKnifeAI/agent-skills](https://github.com/DataKnifeAI/agent-skills) repository as a submodule at `.cursor/skills/agent-skills/`.

After clone, initialize submodules:

```bash
git submodule update --init --recursive
```

To update the skills pointer later:

```bash
cd .cursor/skills/agent-skills && git fetch && git checkout <revision> && cd ../../..
git add .cursor/skills/agent-skills && git commit -m "Bump agent-skills submodule"
```

## Hooks

Optional project hooks live in `.cursor/hooks.json` (see [Hooks](https://cursor.com/docs/hooks)).
