# Baïkal on Railway — CalDAV & CardDAV sync for every device, one click

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.app/new?github_url=https://github.com/lNamelessl/baikal-railway-template)

Baïkal is the lightweight CalDAV/CardDAV server based on sabre/dav: your own calendar and contact sync that every phone and desktop client speaks natively. This template ships it **zero-configuration at deploy time** — you deploy, open your Railway domain, and finish a 3-minute wizard (set an admin password, keep the SQLite default, done).

Pinned to the stable [`ckulka/baikal`](https://github.com/ckulka/baikal-docker) **0.10.1** build (nginx variant — half the size of the Apache one, no unused TLS layer since Railway terminates HTTPS at the edge). Single service: nginx + PHP-FPM + SQLite, all state on two volumes.

| | |
|---|---|
| App | Baïkal 0.10.1 (ckulka image, nginx variant), served on your Railway domain |
| Credentials | **None shipped** — you create the admin account in the first-boot wizard |
| Database | SQLite, stored on a Railway volume — no external database service |
| Persistence | One Railway volume at `/var/www/baikal` (covers both `Specific` and `config`; Railway mounts one volume per service) — data survives restarts and redeploys |
| Endpoints | CalDAV `https://<domain>/cal.php/` · CardDAV `https://<domain>/card.php/` · combined `https://<domain>/dav.php/` · `/.well-known/caldav` and `/.well-known/carddav` auto-redirect |

# Deploy and Host

## About Hosting

Deploying this template provisions exactly one Railway service:

- **baikal** — built from the pinned `ckulka/baikal:0.10.1-nginx` image plus a small boot wrapper ([`railway-entrypoint.sh`](./railway-entrypoint.sh)) that, on every boot: seeds the volume with Baïkal's application files on first boot, refreshes the application code on later boots (so image upgrades take effect) while preserving your data, then hands off to the untouched upstream entrypoint (which fixes file permissions and starts nginx + PHP-FPM).

One Railway volume is mounted at `/var/www/baikal` — Baïkal keeps its entire state there (SQLite database, admin account, calendars, address books in `Specific/`, plus `config/`), so your data survives every restart and redeploy. Railway attaches a single volume per service; both of the image's persistent directories live under this one mount.

There is **nothing to type at deploy time**: the only template variable, `BAIKAL_SERVERNAME`, is filled automatically from your Railway domain (`${{RAILWAY_PUBLIC_DOMAIN}}`). The admin account is created by you, in the browser, on first visit.

## The 3-minute wizard (first boot)

1. Open your Railway domain (`https://<domain>/`). Baïkal shows its **initialization wizard**.
2. Set an **admin password** (the login name is fixed to `admin`) and continue.
3. Keep the **SQLite** database default and submit.
4. Click **Start using Baïkal**, log in at `/admin` with `admin` + your password — done. CalDAV/CardDAV are live immediately.

## Connect your devices

| Client | How |
|---|---|
| **iOS / iPadOS** (calendar) | Settings → Apps → Calendar → Calendar Accounts → Add Account → Other → **CalDAV** — Server: `<domain>`, User: `admin`, Password: your wizard password |
| **iOS / iPadOS** (contacts) | Same path → **CardDAV** — same server/user/password |
| **Android** | [DAVx⁵](https://www.davx5.com/) → `+` → **Login URL**: `https://<domain>/` (auto-discovery) or `https://<domain>/dav.php/` — user `admin` |
| **Thunderbird** (calendar) | Calendar tab → New Calendar → **On the Network** → URL `https://<domain>/cal.php/` |
| **Thunderbird** (contacts) | CardBook add-on → New Address Book → CardDAV → `https://<domain>/card.php/` |

All clients authenticate with the admin account you created in the wizard (or any extra user you create in the Baïkal admin panel under *Users*). macOS Calendar/Contacts and GNOME Evolution/GNOME Online Accounts work the same way — point them at the domain or at `/dav.php/`.

## Security notes

- `/var/www/baikal/Specific` holds your SQLite database. The image's nginx config **denies web access to `/Specific` and `/Core`** (they answer 404), and Railway volumes are not web-reachable by themselves anyway. This is the one directory upstream warns must never be served — it never is, here.
- All traffic is TLS-terminated by Railway's edge; the container only listens on HTTP port 80 internally.

## Image-lag disclosure

The pinned `ckulka/baikal` image packages **Baïkal 0.10.1**; upstream Baïkal is at **0.12.1** (which includes a fix for a reflected XSS). The image maintainer had not published 0.11/0.12 tags at the time this template was verified — [`0.10.1-nginx`](https://github.com/ckulka/baikal-docker/pkgs/container/baikal) is the newest *versioned* tag available. This is the standard trade-off of the de facto standard Baïkal image; bumping is a one-line change to the [Dockerfile](./Dockerfile) when a new tag lands. Practical advice for the current gap: create Baïkal **users** (share calendars with family/teammates) from the admin panel rather than sharing the admin login.

## Troubleshooting

- **Wizard asks to log in immediately / no wizard?** The volume already holds a config — a previous deploy initialized Baïkal. Delete the volume (or the project) and redeploy fresh to restart the wizard.
- **CalDAV client can't connect?** Check the URL ends in `.php` and, when entered manually, ends with `/` (`/cal.php/`, not `/cal.php`). Try `https://<domain>/dav.php/` if your client does no well-known discovery. Check the user/password in the Baïkal admin panel.
- **404 on `/Specific/...`?** Expected — that path is blocked on purpose (it holds the database).
- **Permission errors in deploy logs mentioning `chown`?** The image fixes permissions on boot as root; if your logs show `Operation not permitted`, redeploy once — and please open an issue on the template repo.
- **Need email for calendar invitations?** Baïkal supports SMTP relay via its admin panel (or the image's msmtp support); on Railway you can point it at any SMTP provider. Not required for sync.

## Local development

```bash
docker build -t baikal-railway .
docker run --rm -p 8080:80 baikal-railway
# open http://localhost:8080
```
