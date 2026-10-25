# Current workflow — trusted publishing + staged publishing

Verified 2026-10-24. Cached from `npm/documentation`; re-verify via the freshness check.

## Version gates

- Trusted publishing: npm CLI ≥ 11.5.1 (v12 current), Node ≥ 22.14.0
- Staged publishing: npm CLI ≥ 11.15.0
- dist-tag via OIDC: npm CLI ≥ 11.21.0 or ≥ 12.2.0

## GitHub Actions (the common case)

```yaml
name: Publish Package
on:
  push:
    tags: ['v*']
permissions:
  id-token: write   # required for OIDC
  contents: read
jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v6
        with:
          node-version: '24'
          registry-url: 'https://registry.npmjs.org'
          package-manager-cache: false   # never cache in release builds
      - run: npm ci
      - run: npm run build --if-present
      - run: npm stage publish   # staged; or npm publish if stage not desired
```

## Maximum security posture

1. Trusted publisher with **stage-only** permissions (allow `npm stage publish`, not `npm publish`).
2. Package setting **"Require two-factor authentication and disallow tokens"**.
3. Migration path: set up trusted publishers → verify → restrict tokens → revoke old automation tokens.

## Provenance

- Auto-generated with trusted publishing from GitHub Actions or GitLab — no `--provenance` flag needed.
- Not generated for: CircleCI, private repositories.
- Verify locally with `npm audit signatures`.

## Private dependencies

Trusted publishing covers `npm publish`, not `npm install`. For private deps, use a
read-only granular token:

```yaml
      - run: npm ci
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_READ_TOKEN }}
```

`repository.url` in `package.json` must exactly match the GitHub repo for trusted publishing to work.
