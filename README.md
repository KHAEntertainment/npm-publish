# npm-publish

[![skills.sh](https://skills.sh/b/KHAEntertainment/npm-publish)](https://skills.sh/KHAEntertainment/npm-publish)

A Claude Code skill that keeps agents on npm's **current** publishing methodology, not the token workflow their training data remembers.

Agents (and models) keep defaulting to `npm token create` → `NPM_TOKEN` secret → `NODE_AUTH_TOKEN`, and to bypassing 2FA. npm has moved on: the current path is **OIDC trusted publishing** (`id-token: write`, no long-lived token) plus **staged publishing** (`npm stage publish` → maintainer approves with 2FA), with **provenance** generated automatically.

This skill kicks in whenever publishing to npm is in scope and redirects the agent to the current method.

## Install

**Claude Code — via the KHA marketplace:**

```
/plugin marketplace add KHAEntertainment/marketplace
/plugin install npm-publish@kha-marketplace
```

**Any agent (Claude Code, Codex, Open Code, Cursor, Windsurf, Gemini, Copilot, Cline, AMP, Antigravity, OpenClaw, …) — via skills.sh:**

```
npx skills add KHAEntertainment/npm-publish
```

Or install it to every supported agent on the machine at once:

```
npx skills add KHAEntertainment/npm-publish -a '*'
```

## How it stays current

The skill splits its facts three ways and treats each differently, so it does not rot:

- **Volatile** — which workflow is current, exact flags — is never stored as prose; it is fetched live from `npm/documentation` (`scripts/fetch_npm_docs.sh`) at authoring time, with an offline fallback that warns instead of failing silently.
- **Cached** — the redirect table and version gates in `references/` — carry a `Verified` date and are re-checked on every load (`scripts/check-freshness.sh`).
- **Frozen** — the owner's publishing policy (trusted publishing + staged publishing; never issue automation tokens) — is stored once and never auto-changed.

A version pin (`metadata.pins: npm`) plus `scripts/check-staleness.sh` flags a CLI major bump as a signal to re-read the changelog.

## The redirect, in one line

> `npm token create` → `NPM_TOKEN` secret is deprecated. The current path is OIDC trusted publishing + staged publishing, token-free, 2FA at the approval step.
