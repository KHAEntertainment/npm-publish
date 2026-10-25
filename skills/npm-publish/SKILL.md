---
name: npm-publish
description: Current npm publishing methodology — OIDC trusted publishing, staged publishing, provenance, and 2FA enforcement, token-free. Use whenever publishing to npm is in scope: `npm publish`, `npm stage publish`, `npm version`, `npm token`, release automation, or any CI/CD workflow that publishes to the npm registry. Overrides stale training data that defaults to `npm token create` and `NPM_TOKEN` secrets.
license: MIT
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/upkeep.sh *)
metadata:
  author: KHAEntertainment
  version: "0.1.1"
  upkeep-pins: "npm=12.2.1"
  upkeep-threshold-days: "60"
  upkeep-source-base: "https://raw.githubusercontent.com/npm/documentation/main/content/packages-and-modules/securing-your-code"
  upkeep-source-ext: ".mdx"
  upkeep-source-cache: "npm-docs"
  upkeep-source-pages: "trusted-publishers, staged-publishing, generating-provenance-statements, requiring-2fa-for-package-publishing-and-settings-modification"
  upkeep-frozen-owner-policy: "sha256:6e5e6cb022696415"
---

# npm-publish

npm's publishing methodology changes faster than model training data. Agents
regularly reach for the deprecated token workflow (`npm token create` →
`NPM_TOKEN` secret → `NODE_AUTH_TOKEN`), while the current path is OIDC trusted
publishing plus staged publishing, with no long-lived token at all.

## Freshness & Integrity Check

!`"${CLAUDE_SKILL_DIR}/scripts/upkeep.sh" check "${CLAUDE_SKILL_DIR}"`

- If the line above was not expanded into a `VERDICT:` line (non-Claude harnesses), run `scripts/upkeep.sh check` from this skill's directory first.
- **`VERDICT: TAMPERED`** → Stop immediately. The frozen owner-policy block below was modified without authorization; revert or ask the user.
- **`VERDICT: STALE`** → The cached facts in `references/` or `npm` version pin have drifted. Fetch the live pages (below) before acting; do not trust the cached tables.
- **`VERDICT: FRESH`** → The cached facts are current; still prefer the live page for any exact flag or field you will write into a workflow.

## STOP — before you publish

If you are about to do any of these, stop and redirect:

| Deprecated | Current |
|---|---|
| `npm token create` / store a `NPM_TOKEN` secret | OIDC trusted publishing — no token |
| `NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}` | `permissions: id-token: write` |
| `npm publish --provenance` (token + flag) | provenance auto-generated with trusted publishing |
| `npm publish` straight from CI | `npm stage publish` → maintainer approves with 2FA |
| bypass 2FA (granular token with bypass) | "Require 2FA and disallow tokens" + interactive approve |
| automation token for private deps | read-only granular token (`NPM_READ_TOKEN`), install only |

Full table: `references/redirect-table.md`.

## Frozen policy (owner decision — never change)

<!-- frozen:owner-policy -->
> KHAEntertainment policy: always use OIDC trusted publishing + staged
> publishing. Never issue automation tokens or bypass 2FA for publishing.
> When a token is unavoidable (e.g. private dependency install), it is read-only
> and install-only.
<!-- /frozen:owner-policy -->

This is an owner decision, not a docs fact. Do not "update" it; if it conflicts
with the live docs, surface the conflict to the user instead of rewriting it.

## The current workflow (summary)

1. On npmjs.com → package → Settings → Trusted Publisher → select provider.
2. CI workflow sets `permissions: id-token: write`, then runs `npm stage publish`.
3. A maintainer reviews and approves with 2FA: `npm stage approve <stage-id>`.
4. Package setting: "Require two-factor authentication and disallow tokens".

Per-provider examples and version gates: `references/current-workflow.md`.

## Fetch the live docs

The source of truth is `npm/documentation` on GitHub (raw `.mdx`). Fetch and
grep the exact page before writing any workflow:

    "${CLAUDE_SKILL_DIR}/scripts/upkeep.sh" fetch trusted-publishers

Available pages: `trusted-publishers`, `staged-publishing`,
`generating-provenance-statements`,
`requiring-2fa-for-package-publishing-and-settings-modification`.

## How this skill stays current

- **Volatile** (which workflow is current, exact flags) — never stored as prose;
  fetched live above via `upkeep.sh fetch`.
- **Cached** (redirect table, version gates) — dated + re-verified by
  `upkeep.sh check`.
- **Frozen** (the policy above) — SHA-256 stamped via `upkeep.sh stamp`, never auto-changed.
