#!/usr/bin/env bash
# Renders a page at real phone widths (360/390/414 CSS px) in light and dark,
# and prints layout measurements (page height, horizontal overflow, key
# element boxes) at each width.
#
# This machine's Chrome floors --window-size layout at ~500 CSS px for a
# directly-loaded page (see tools/shots.sh) — but a same-origin iframe of a
# fixed width forces its own layout viewport, so nesting the real page in an
# iframe sidesteps the floor. That requires serving over HTTP (file:// pages
# are cross-origin from each other, so a harness page can't read into the
# iframe) — this script starts its own local server and stops it on exit.
#
# Usage: tools/mobile-shots.sh index.html [vi/index.html ...]
set -u
cd "$(dirname "$0")/.."
CHROME="${CHROME_PATH:-C:/Program Files/Google/Chrome/Application/chrome.exe}"
PORT="${MOBILE_SHOTS_PORT:-8931}"
site="tools/.tmp/mobile-site"; outdir="tools/.tmp/mobile"
rm -rf "$site" "$outdir"; mkdir -p "$site" "$outdir"
cp -r ./*.html styles.css brand img favicon* site.webmanifest "$site"/ 2>/dev/null; [ -d vi ] && cp -r vi "$site"/
# Dark run: promote the dark media block to unconditional so headless Chrome renders it.
sed 's/@media (prefers-color-scheme: dark)/@media all/' styles.css > "$site/styles-dark.css"
for f in "$site"/*.html "$site"/vi/*.html; do
  [ -f "$f" ] || continue
  sed -E 's#href="(\.\./)?styles\.css"#href="\1styles-dark.css"#' "$f" > "${f%.html}.dark.html"
done

server_pid=""
cleanup() { [ -n "$server_pid" ] && kill "$server_pid" 2>/dev/null; }
trap cleanup EXIT
python -m http.server "$PORT" --bind 127.0.0.1 --directory "$site" >/dev/null 2>&1 &
server_pid=$!
for _ in $(seq 1 20); do
  curl -sS -o /dev/null "http://127.0.0.1:$PORT/" && break
  sleep 0.25
done

measure_js='
const f = document.getElementById("f");
f.addEventListener("load", () => {
  const d = f.contentDocument, w = f.contentWindow, L = [];
  const de = d.documentElement;
  L.push("viewport      : " + w.innerWidth + " x " + w.innerHeight);
  L.push("page height   : " + de.scrollHeight + " px");
  L.push("h-overflow    : scrollWidth=" + de.scrollWidth + " clientWidth=" + de.clientWidth +
         (de.scrollWidth > de.clientWidth ? "  <<< HORIZONTAL OVERFLOW" : "  ok"));
  const wide = [];
  d.querySelectorAll("*").forEach(el => {
    const r = el.getBoundingClientRect();
    if (r.width > de.clientWidth + 1) wide.push("    " + el.tagName.toLowerCase() +
      (el.className ? "." + String(el.className).trim().split(/\s+/).join(".") : "") +
      "  w=" + Math.round(r.width));
  });
  L.push("elements wider than viewport: " + (wide.length ? "\n" + wide.join("\n") : "none"));
  const show = (sel, label) => {
    const el = d.querySelector(sel); if (!el) return;
    const r = el.getBoundingClientRect();
    L.push(label.padEnd(22) + ": " + Math.round(r.width) + " x " + Math.round(r.height) +
           "  bottom=" + Math.round(r.bottom + w.scrollY));
  };
  show(".hero .device", "hero device");
  show(".store-badge img", "play badge");
  show(".step:nth-of-type(1) .device", "step 1 device");
  document.getElementById("out").textContent = L.join("\n");
});
'

for page in "$@"; do
  name=$(echo "${page%.html}" | tr '/' '_')
  for theme in light dark; do
    src="/$page"; [ "$theme" = dark ] && src="/${page%.html}.dark.html"
    for w in 360 390 414; do
      harness="$site/harness-$name-$w-$theme.html"
      cat > "$harness" <<HTML
<!doctype html><html><head><meta charset="utf-8"></head><body style="margin:0">
<iframe id="f" src="$src" width="$w" height="900" style="border:0"></iframe>
<pre id="out">pending</pre>
<script>$measure_js</script>
</body></html>
HTML
      url="http://127.0.0.1:$PORT/${harness#$site/}"
      if [ "$theme" = light ]; then
        echo "═══ $page @ ${w}px ═══"
        "$CHROME" --headless=new --virtual-time-budget=8000 --dump-dom "$url" 2>/dev/null \
          | sed -n '/<pre id="out">/,/<\/pre>/p' | sed -e 's#<pre id="out">##' -e 's#</pre>##'
        echo
      fi
      "$CHROME" --headless=new --hide-scrollbars --force-device-scale-factor=1 \
        --window-size="$((w+20)),3600" \
        --screenshot="$(cygpath -m "$(pwd)/$outdir")/$name-$w-$theme.png" "$url" 2>/dev/null
    done
  done
done
echo "Screenshots: $outdir/*.png"
