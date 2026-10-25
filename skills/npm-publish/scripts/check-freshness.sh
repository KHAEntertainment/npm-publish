#!/usr/bin/env bash
# check-freshness.sh — flag stale "Verified" dates in a documentation skill.
#
# Usage: check-freshness.sh [skill-dir] [threshold-days]
#   Scans <skill-dir>/SKILL.md and <skill-dir>/references/*.md for "Verified ...
#   on YYYY-MM-DD" (or "Verified YYYY-MM-DD;") markers, computes each date's age,
#   and prints one FRESH/STALE line per marker plus a VERDICT. Always exits 0 so
#   dynamic context injection ( `!`...` ) never aborts on it.
#   Threshold defaults to 60 days.
set -uo pipefail

skill_dir="${1:-$PWD}"
skill_dir="${skill_dir%/}"
threshold="${2:-60}"

if [[ ! -f "$skill_dir/SKILL.md" ]]; then
  echo "UNKNOWN — no SKILL.md under ${skill_dir:-<cwd>}"
  exit 0
fi

python3 - "$skill_dir" "$threshold" <<'PY'
import re, sys, datetime, pathlib

skill_dir = pathlib.Path(sys.argv[1])
threshold = int(sys.argv[2])
today = datetime.date.today()

files = [skill_dir / "SKILL.md"]
refs = sorted((skill_dir / "references").glob("*.md")) if (skill_dir / "references").is_dir() else []
files += refs

items = []
seen = set()
for f in files:
    if not f.exists():
        continue
    lines = f.read_text(encoding="utf-8").splitlines()
    label = "SKILL.md" if f.name == "SKILL.md" else "references/" + f.name
    for i, line in enumerate(lines):
        if "erified" not in line:
            continue
        # "Verified ... on <date>" may wrap to the next line; check this line + one more.
        window = " ".join(lines[i:i + 2])
        for m in re.finditer(r"\d{4}-\d{2}-\d{2}", window):
            key = (label, m.group(0))
            if key in seen:
                continue
            seen.add(key)
            items.append(key)

if not items:
    print('VERDICT: UNKNOWN — no "Verified" dates found')
else:
    stale = 0
    for label, d in items:
        try:
            dt = datetime.date.fromisoformat(d)
        except ValueError:
            print(f"??       {label}  {d}  (unparseable date)")
            continue
        age = (today - dt).days
        if age > threshold:
            print(f"STALE    {label}  {d} ({age}d) — over {threshold}d, RE-VERIFY")
            stale += 1
        else:
            print(f"FRESH    {label}  {d} ({age}d)")
    if stale:
        print(f"VERDICT: STALE — {stale} of {len(items)} verified item(s) over {threshold} days; re-verify before relying on them")
    else:
        print(f"VERDICT: FRESH — {len(items)} verified item(s) within {threshold} days")
PY
exit 0
