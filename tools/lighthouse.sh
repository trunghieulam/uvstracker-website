#!/usr/bin/env bash
# Lighthouse ≥ 95 gate. Usage: tools/lighthouse.sh index.html privacy.html …  (needs network on first run)
set -u
cd "$(dirname "$0")/.."
export CHROME_PATH="${CHROME_PATH:-C:/Program Files/Google/Chrome/Application/chrome.exe}"
mkdir -p tools/.tmp
python -m http.server 8765 --bind 127.0.0.1 >/dev/null 2>&1 & srv=$!
trap 'kill $srv 2>/dev/null' EXIT
sleep 1
fail=0
for p in "$@"; do
  out="tools/.tmp/lh-$(echo "$p" | tr '/' '_').json"
  npx --yes lighthouse@12 "http://127.0.0.1:8765/$p" --quiet --chrome-flags="--headless=new" \
    --only-categories=performance,accessibility,best-practices,seo --output=json --output-path="$out" >/dev/null 2>&1
  python - "$out" "$p" <<'EOF' || fail=1
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))["categories"]
scores = {k: round(v["score"] * 100) for k, v in d.items()}
print(sys.argv[2] + ": " + "  ".join(f"{k}={v}" for k, v in scores.items()))
sys.exit(0 if all(v >= 95 for v in scores.values()) else 1)
EOF
done
exit $fail
