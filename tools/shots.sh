#!/usr/bin/env bash
# Renders one page at 500/768/1280 CSS px in light and dark. Usage: tools/shots.sh index.html
# 500 is this Chrome's layout-width floor, not a real target — see uv-website-deploy skill.
set -u
cd "$(dirname "$0")/.."
CHROME="${CHROME_PATH:-C:/Program Files/Google/Chrome/Application/chrome.exe}"
page="$1"; name=$(echo "${page%.html}" | tr '/' '_')
site="tools/.tmp/site"; rm -rf "$site"; mkdir -p "$site" tools/.tmp/shots
cp -r ./*.html styles.css brand img favicon* site.webmanifest "$site"/ 2>/dev/null; [ -d vi ] && cp -r vi "$site"/
# Dark run: promote the dark media block to unconditional so headless Chrome renders it.
sed 's/@media (prefers-color-scheme: dark)/@media all/' styles.css > "$site/styles-dark.css"
root=$(cygpath -m "$(pwd)" | sed 's/ /%20/g')
outdir=$(cygpath -m "$(pwd)/tools/.tmp/shots")
for theme in light dark; do
  src="$site/$page"
  if [ "$theme" = dark ]; then
    sed -E 's#href="(\.\./)?styles\.css"#href="\1styles-dark.css"#' "$src" > "${src%.html}.dark.html"; src="${src%.html}.dark.html"
  fi
  for w in 500 768 1280; do
    out="$outdir/$name-$w-$theme.png"
    "$CHROME" --headless=new --hide-scrollbars --force-device-scale-factor=1 --window-size="$w,4600" \
      --screenshot="$out" "file:///$root/$src" 2>/dev/null
  done
done
ls -1 tools/.tmp/shots/"$name"-*
