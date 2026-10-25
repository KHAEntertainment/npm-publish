# npm-publish skill

[![skills.sh](https://skills.sh/b/KHAEntertainment/npm-publish)](https://skills.sh/KHAEntertainment/npm-publish)

A Claude Code skill (and cross-harness Agent Skill) that keeps agents on npm's **current** publishing methodology, not the often outdated workflow their training data remembers.

Agents (and models) keep defaulting to `npm token create` → `NPM_TOKEN` secret → `NODE_AUTH_TOKEN`, and to bypassing 2FA. npm has moved on: the current path is **OIDC trusted publishing** (`id-token: write`, no long-lived token) plus **staged publishing** (`npm stage publish` → maintainer approves with 2FA), with **provenance** generated automatically.

This skill kicks in whenever publishing to npm is in scope and redirects the agent to the current method.

## Install

### Claude Code (`kha-marketplace`)

```bash
/plugin marketplace add KHAEntertainment/marketplace
/plugin install npm-publish@kha-marketplace
```

### Any Agent Skills harness (`skills.sh`)

```bash
npx skills add KHAEntertainment/npm-publish
```

## What's inside

```text
skills/npm-publish/
├── SKILL.md                        # Redirect gate + frozen owner policy + live-fetch entry
├── references/
│   ├── redirect-table.md           # Deprecated habit → current equivalent (dated)
│   └── current-workflow.md         # Trusted + staged publishing per CI provider (dated)
└── scripts/
    └── upkeep.sh                   # Unified runtime: check | fetch | stamp | sync (v0.2.0)
```

## How it stays current without drifting

The skill separates three kinds of content and governs each with `scripts/upkeep.sh`:

- **Volatile** — exact CLI flags, provider setup steps, and runner requirements are fetched live from `npm/documentation` on GitHub (`scripts/upkeep.sh fetch <page>`, cached 12h with loud offline fallback).
- **Cached** — the redirect table ("when your instinct says X, do Y") and version gates carry a `Verified YYYY-MM-DD` date (`scripts/upkeep.sh check` flags pins or dates >60 days old as **STALE**).
- **Frozen** — the owner's publishing policy (trusted publishing + staged publishing; never issue automation tokens) is wrapped in `<!-- frozen:owner-policy -->` and SHA-256 stamped (`upkeep-frozen-owner-policy`) so any unauthorized edit triggers `VERDICT: TAMPERED`.

## The redirect, in one line

> `npm token create` → `NPM_TOKEN` secret is deprecated. The current path is OIDC trusted publishing + staged publishing, token-free, 2FA at the approval step.
