#!/usr/bin/env bash
# Structural rules for uvstracker.com. Usage: tools/check.sh [page.html …]  (no args = every page)
set -u
cd "$(dirname "$0")/.."
pages=("$@"); [ ${#pages[@]} -eq 0 ] && pages=( *.html vi/*.html learn/*.html vi/learn/*.html )
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
  if grep -oiE '<script[^>]*>' "$p" | grep -viE 'type="application/ld\+json"' | grep -q .; then
    err "$p" "executable <script> — the site is zero-JS (JSON-LD excepted)"
  fi
  grep -qiE 'lorem|TODO|TBD' "$p" && err "$p" "placeholder text"
  grep -q 'https://uvstracker\.com' "$p" && err "$p" "apex host — use https://www.uvstracker.com"
  # Positive framing: the word 'burn' only inside 'sunburn'.
  if grep -ioE '[a-z]*burn[a-z]*' "$p" | grep -viE '^sunburn' | grep -q .; then err "$p" "'burn' outside 'sunburn'"; fi
  case "$p" in
    learn/index.html|vi/learn/index.html) ;;
    learn/*.html|vi/learn/*.html)
      grep -q 'class="byline"' "$p" || err "$p" "learn page without byline"
      grep -q 'class="references"' "$p" || err "$p" "learn page without references section"
      grep -q 'class="disclaimer"' "$p" || err "$p" "learn page without disclaimer"
      grep -q 'application/ld+json' "$p" || err "$p" "learn page without JSON-LD"
      n=$(grep -c 'class="copy-attribution"' "$p")
      [ "$n" -ge 1 ] && [ "$n" -le 2 ] || err "$p" "copy-attribution spans: $n (need 1-2)"
      ;;
  esac
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
