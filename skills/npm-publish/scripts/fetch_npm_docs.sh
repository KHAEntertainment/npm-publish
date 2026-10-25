#!/usr/bin/env bash
# Fetch raw npm doc pages (.mdx) from npm/documentation into a local cache so
# they can be grepped exactly. Summarizing fetchers paraphrase flags and
# requirements; the raw page cannot.
#
# Usage: fetch_npm_docs.sh <page> [<page> ...]
#        e.g. fetch_npm_docs.sh trusted-publishers staged-publishing
#
# Pages resolve under content/packages-and-modules/securing-your-code/ in the
# npm/documentation repo (main branch). Prints the cached file path for each
# page (stdout). Cache refreshes after 12 hours; on fetch failure it falls back
# to any cached copy and warns on stderr that the content may be stale.
set -uo pipefail

BASE="${NPM_DOCS_BASE:-https://raw.githubusercontent.com/npm/documentation/main}"
CACHE="${NPM_DOCS_CACHE:-${TMPDIR:-/tmp}/npm-docs}"
mkdir -p "$CACHE"
CURL=(curl -fsSL --max-time 30)

warn() { printf '⚠ %s\n' "$@" >&2; }

# Portable mtime as YYYY-MM-DD (empty if unknown).
file_mtime() {
  local d
  d="$(stat -f '%Sm' -t '%Y-%m-%d' "$1" 2>/dev/null)" || d="$(stat -c '%y' "$1" 2>/dev/null | cut -d' ' -f1)"
  printf '%s' "$d"
}

[[ $# -gt 0 ]] || { echo "usage: $0 <page>..." >&2; echo "pages: trusted-publishers, staged-publishing, generating-provenance-statements, requiring-2fa-for-package-publishing-and-settings-modification" >&2; exit 2; }

for page in "$@"; do
  page="${page%.mdx}"
  path="packages-and-modules/securing-your-code/${page}"
  out="$CACHE/${path//\//__}.mdx"
  if [[ -s "$out" && -z "$(find "$out" -mmin +720 2>/dev/null)" ]]; then
    echo "$out"
    continue
  fi
  if "${CURL[@]}" "$BASE/content/$path.mdx" -o "$out.tmp"; then
    mv "$out.tmp" "$out"
    echo "$out"
    continue
  fi
  rm -f "$out.tmp"
  if [[ -s "$out" ]]; then
    warn "OFFLINE/FETCH-FAILED: $page — falling back to cached copy from $(file_mtime "$out")."
    warn "  content may be stale; re-verify against the live page when online."
    echo "$out"
  else
    warn "OFFLINE/FETCH-FAILED: $page — no cached copy and the live page is unreachable."
    warn "  this page is UNAVAILABLE; do not guess its contents."
  fi
done
