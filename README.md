# uvstracker.com

The public website for the **UV Tracker** app — landing page, privacy policy, terms and support.

Hand-written static HTML and one stylesheet. No framework, no build step, no dependencies. It is
meant to load instantly, stay legible for years, and never break because a toolchain moved on.

## Why it exists

The privacy policy is the load-bearing page. Google Play requires a publicly reachable policy URL
before an app that uses location or the camera can be published, and AdMob and Firebase require one
before they may be used at all. Everything else on the site is secondary to that.

## Pages

| File | Purpose |
| :--- | :--- |
| `index.html` | What the app does, and the free-forever promise |
| `privacy.html` | Privacy policy — **keep accurate to the shipped app** |
| `terms.html` | Terms of use, incl. the not-a-medical-device disclaimer |
| `support.html` | FAQ and contact route, required by store listings |
| `styles.css` | The whole stylesheet; light and dark via `prefers-color-scheme` |
| `CNAME` | Custom domain for GitHub Pages |

## Local preview

No server needed — open `index.html` in a browser. To serve it properly:

```bash
python -m http.server 8000
```

## Deploying

GitHub Pages, from the default branch root:

1. Repo → **Settings → Pages** → Source: *Deploy from a branch* → `main` / `/ (root)`.
2. `CNAME` already declares `uvstracker.com`, so Pages picks the custom domain up.
3. At the DNS registrar, point the apex domain at GitHub Pages:
   - `A` records → `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153`
   - and a `CNAME` for `www` → `trunghieulam.github.io`
4. Back in Settings → Pages, tick **Enforce HTTPS** once the certificate is issued.

## Before publishing — two things that still need a decision

1. **The contact addresses are placeholders.** The pages reference `privacy@uvstracker.com`,
   `support@uvstracker.com` and `hello@uvstracker.com`. Set up forwarding for these at the domain
   registrar, or change them to a real address. A privacy policy with a dead contact address fails
   its purpose, and Play reviewers do check.
2. **The privacy policy describes the app as it is today** — no accounts, no advertising, no
   analytics. It is version 1 and dated. The moment sign-in, cloud sync or AdMob ships, it must be
   updated to version 2 *before* those features reach users, since it would otherwise be
   inaccurate in exactly the way regulators care about.

## Keeping the policy honest

The policy makes concrete promises the app currently keeps: camera images are processed on-device
and deleted, nothing but coordinates leaves the phone, and there is no tracking. If a future change
would make any of those statements untrue, the policy changes first.
