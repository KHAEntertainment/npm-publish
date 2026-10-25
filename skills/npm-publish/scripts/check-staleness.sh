#!/usr/bin/env bash
# check-staleness.sh — compare a skill's `metadata.pins` against the live registry.
#
# Usage: check-staleness.sh [skill-dir]
#   Defaults to the current directory. Reads <skill-dir>/SKILL.md, extracts the
#   `metadata.pins` map, and prints one FRESH/STALE line per pin plus a VERDICT.
#   Always exits 0: a stale skill is not a command failure, so dynamic context
#   injection ( `!`...` ) never aborts on it.
#
# Pin forms (flat map under `metadata:`):
#   pins:
#     three: 0.160.0                                          # npm package
#     gsap: { kind: github, repo: greensock/GSAP, version: 3.12.0 }   # git tag
set -uo pipefail

skill_dir="${1:-$PWD}"
skill_dir="${skill_dir%/}"
sk="$skill_dir/SKILL.md"
if [[ ! -f "$sk" ]]; then
  echo "UNKNOWN — no SKILL.md under ${skill_dir:-<cwd>}"
  exit 0
fi

# Extract pins as name<TAB>version<TAB>kind<TAB>repo lines.
pins="$(
  python3 - "$sk" <<'PY'
import re, sys
txt = open(sys.argv[1], encoding="utf-8").read()
m = re.match(r'---\n(.*?)\n---', txt, re.S)
if not m:
    sys.exit(0)
fm = m.group(1)
meta = re.search(r'^metadata:\s*$(.*?)(?=^[^\s]|\Z)', fm, re.M | re.S)
if not meta:
    sys.exit(0)
pm = re.search(r'^\s+pins:\s*$(.*?)(?=^\s{0,3}[A-Za-z_]|\Z)', meta.group(1), re.M | re.S)
if not pm:
    sys.exit(0)
for line in pm.group(1).splitlines():
    s = line.strip()
    if not s or s.startswith('#'):
        continue
    if ':' not in s:
        continue
    key, _, val = s.partition(':')
    key, val = key.strip().strip('"\' '), val.strip().strip('"\' ')
    if val.startswith('{'):
        kind = re.search(r'kind:\s*(\w+)', val)
        kind = kind.group(1) if kind else 'npm'
        repo = re.search(r'repo:\s*([A-Za-z0-9_./-]+)', val)
        repo = repo.group(1) if repo else ''
        ver = re.search(r'version:\s*([^\s,}]+)', val)
        ver = ver.group(1) if ver else ''
        ver = ver.strip().strip('"\' ')
        print(f"{key}\t{ver}\t{kind}\t{repo}")
    else:
        print(f"{key}\t{val}\tnpm\t")
PY
)"

# Split a version into segments (drop leading 'v', split on . _ -).
ver_parts() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/^v//' | tr '._-' ' '; }

# cmp: 1 if $1 < $2, 0 if equal, 2 if $1 > $2 (numeric-leading semver, best-effort).
ver_cmp() {
  local -a a b
  read -r -a a <<< "$(ver_parts "$1")"
  read -r -a b <<< "$(ver_parts "$2")"
  local i=0 av bv
  while :; do
    av="${a[$i]:-}"; bv="${b[$i]:-}"
    if [[ -z "$av" && -z "$bv" ]]; then return 0; fi
    if [[ "$av" =~ ^[0-9]+$ && "$bv" =~ ^[0-9]+$ ]]; then
      (( 10#$av < 10#$bv )) && return 1
      (( 10#$av > 10#$bv )) && return 2
    elif [[ "$av" != "$bv" ]]; then
      [[ "$av" < "$bv" ]] && return 1 || return 2
    fi
    ((i++))
  done
}

stale=0; total=0; manual=0
while IFS=$'\t' read -r name ver kind repo; do
  [[ -z "$name" ]] && continue
  total=$((total+1))
  cur=""
  if [[ "$kind" == "manual" ]]; then
    echo "MANUAL   $name  $ver  (no auto-registry — check vendor releases)"
    manual=$((manual+1))
    continue
  fi
  if [[ "$kind" == "github" ]]; then
    [[ -z "$repo" ]] && repo="$name"
    cur="$(git ls-remote --tags --refs "https://github.com/${repo}.git" 2>/dev/null | sed 's#.*refs/tags/##' | grep -vF '^{}' | sort -V | tail -1)"
    cur="${cur#v}"
  else
    cur="$(npm view "$name" version 2>/dev/null)"
  fi
  if [[ -z "$cur" ]]; then
    echo "UNKNOWN  $name  (pinned ${ver:-?} — current could not be resolved)"
    continue
  fi
  ver_cmp "${ver:-0}" "$cur"
  case $? in
    0) echo "FRESH    $name  $cur" ;;
    1) echo "STALE    $name  pinned ${ver} → current $cur"; stale=$((stale+1)) ;;
    2) echo "AHEAD    $name  pinned ${ver} → current $cur" ;;
  esac
done <<< "$pins"

if (( total == 0 )); then
  echo "VERDICT: UNKNOWN — no metadata.pins found in ${skill_dir}/SKILL.md"
else
  auto=$((total - manual))
  if (( stale > 0 )); then
    echo "VERDICT: STALE — $stale of $auto pin(s) outdated${manual:+ (+$manual manual)}"
  else
    echo "VERDICT: FRESH — $auto pin(s) current${manual:+ (+$manual manual)}"
  fi
fi
exit 0
