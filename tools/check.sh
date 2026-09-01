#!/usr/bin/env bash
# Structural rules for uvstracker.com. Usage: tools/check.sh [page.html …]  (no args = every page)
set -u
cd "$(dirname "$0")/.."
pages=("$@"); [ ${#pages[@]} -eq 0 ] && pages=( *.html vi/*.html )
fail=0
err() { echo "FAIL $1: $2"; fail=1; }

for p in "${pages[@]}"; do
  [ -f "$p" ] || { err "$p" "missing"; continue; }
  dir=$(dirname "$p")
  grep -q '<html lang="' "$p" || err "$p" "no <html lang>"
  for needle in 'name="viewport"' 'name="description"' 'property="og:title"' 'property="og:description"' \
                'property="og:image"' 'name="twitter:card"' 'rel="canonical"' 'rel="icon"' 'rel="manifest"'; do
    grep -q "$needle" "$p" || err "$p" "missing $needle"
  done
  grep -qi '<script' "$p" && err "$p" "contains <script> — the site is zero-JS"
  grep -qiE 'lorem|TODO|TBD' "$p" && err "$p" "placeholder text"
  grep -q 'https://uvstracker\.com' "$p" && err "$p" "apex host — use https://www.uvstracker.com"
  # Positive framing: the word 'burn' only inside 'sunburn'.
  if grep -ioE '[a-z]*burn[a-z]*' "$p" | grep -viE '^sunburn' | grep -q .; then err "$p" "'burn' outside 'sunburn'"; fi
  while read -r tag; do
    for a in alt width height; do echo "$tag" | grep -q " $a=" || err "$p" "img without $a: $tag"; done
  done < <(grep -oE '<img[^>]*>' "$p")
  while read -r ref; do
    ref="${ref%%\?*}"
    case "$ref" in
      /) target="index.html" ;;
      /*) target=".$ref" ;;
      *) target="$dir/$ref" ;;
    esac
    [ -e "$target" ] || err "$p" "broken link: $ref"
  done < <(grep -oE '(href|src)="[^"#]+"' "$p" | sed -E 's/^(href|src)="//; s/"$//' \
           | grep -vE '^(https?:|mailto:|tel:|//)' | sort -u)
done

for f in sitemap.xml robots.txt; do
  grep -q 'https://uvstracker\.com' "$f" && err "$f" "apex host — use https://www.uvstracker.com"
done

# Screenshot weight budget (spec §5).
for f in img/*/*.png; do
  [ -f "$f" ] || continue
  s=$(stat -c %s "$f"); [ "$s" -le 256000 ] || err "$f" "over 250 KB ($s bytes)"
done

# Markup validity. First run downloads html-validate (needs network).
npx --yes html-validate@8 "${pages[@]}" || fail=1

[ $fail -eq 0 ] && echo "check.sh: OK (${#pages[@]} pages)"
exit $fail
