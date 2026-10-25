# Redirect table — deprecated → current

Verified 2026-10-24. Cached from `npm/documentation`; re-verify via the freshness check.

| Agent reaches for | Current (as of 2026-10-24) |
|---|---|
| `npm token create` → `NPM_TOKEN` GitHub secret | OIDC trusted publishing (`id-token: write`); no long-lived token |
| `NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}` in workflow | trusted-publisher config; npm CLI auto-detects OIDC, falls back to token |
| `npm publish --provenance` (token + flag) | provenance auto-generated with trusted publishing (GitHub Actions / GitLab) |
| `npm publish` directly from CI | `npm stage publish` → maintainer `npm stage approve` (2FA) |
| granular token with bypass-2FA | "Require two-factor authentication and disallow tokens" (package setting) |
| automation token for private deps | read-only granular access token (`NPM_READ_TOKEN`) for `npm ci` only |
| self-hosted runner OIDC publish | not supported — use hosted runners (GitHub Actions / GitLab.com / CircleCI cloud) |

## Notes

- `npm whoami` is **not** a verification of trusted-publishing permissions; verify with the actual publish/stage operation.
- A trusted-publisher config must complete its **first publish within 2 days** or it expires (delete + recreate to recover).
- Trusted-publisher connections are immutable once created; change = delete + recreate.
- Provenance is **not** generated for CircleCI or private repositories.
- `npm stage publish` does not require 2FA; the maintainer's `npm stage approve` does.
