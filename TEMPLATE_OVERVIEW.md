# Baïkal on Railway — your own CalDAV & CardDAV server, one click

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/APDJCR)

Self-host your calendar and contact sync: Baïkal is the lightweight CalDAV+CardDAV server that iPhones, Android phones (DAVx⁵), Thunderbird, macOS and GNOME all speak natively. This template deploys it **with zero form inputs** — you click deploy, open your Railway domain, and finish a 3-minute wizard (pick an admin password, keep the SQLite default, done).

Pinned to the stable `ckulka/baikal` **0.10.1** build (nginx variant — half the size of the Apache variant, no redundant TLS layer since Railway terminates HTTPS at the edge). Single service, single volume, roughly **$5/month** on Railway's usage-based pricing.

| | |
|---|---|
| App | Baïkal 0.10.1 (ckulka image, nginx variant) on your Railway domain |
| Credentials | **None shipped** — you create the admin account in the first-boot wizard |
| Database | SQLite stored on a Railway volume — no external database service |
| Persistence | One volume at `/var/www/baikal` (covers both `Specific` and `config`) — admin account, calendars, address books survive restarts and redeploys |
| Endpoints | CalDAV `/cal.php/` · CardDAV `/card.php/` · combined `/dav.php/` · `/.well-known/caldav` and `/.well-known/carddav` redirect automatically |

# Deploy and Host

## About Hosting

Deploying this template provisions exactly one Railway service:

- **baikal** — built from the pinned `ckulka/baikal:0.10.1-nginx` image (see the [Dockerfile](https://github.com/lNamelessl/baikal-railway-template/blob/main/Dockerfile)) plus a small boot wrapper that seeds the volume with Baïkal's application files on first boot and refreshes the application code on later boots (so image upgrades take effect) while preserving your data, then hands off to the untouched upstream entrypoint.

One Railway volume is mounted at `/var/www/baikal` — Baïkal keeps its entire state there (SQLite database, admin account, calendars, address books in `Specific/`, plus `config/`), so your data survives every restart and redeploy.

There is **nothing to type at deploy time**: the only template variable, `BAIKAL_SERVERNAME`, fills itself from your Railway domain (`${{RAILWAY_PUBLIC_DOMAIN}}`).

### After deploying

1. Open your Railway domain (`https://<domain>/`). Baïkal shows its **initialization wizard** at `/admin/install/`.
2. Set an **admin password** (the panel login name is `admin`) and continue.
3. Keep the **SQLite** database default and submit, then click **Start using Baïkal**.
4. Log in at `https://<domain>/admin/` with `admin` + your password.
5. Under **Users → + Add user**, create the account your devices will sync with (CalDAV/CardDAV clients use this user, not the panel admin).
6. Point your devices at the server (below) and start syncing.

## Why Deploy

- **Every device already speaks it.** iOS and macOS Calendar/Contacts, Android via DAVx⁵, Thunderbird, GNOME Online Accounts, KDE — no sync app subscriptions, no vendor lock-in, your data on your own instance.
- **Zero deploy inputs.** No prompts, no database service to attach, no env juggling: the SQLite database lives on the volume and the only variable is derived from your Railway domain.
- **Wizard-driven and honest.** The first-boot wizard creates your admin — no default credentials shipped, nothing to leak.
- **Correct persistence.** The volume covers both of the image's persistent directories, and the boot wrapper refreshes application code on upgrade without touching your data.
- **Secure by construction.** The directory holding the SQLite database (`Specific/`) is denied by the image's nginx config (404 — verified), and Railway volumes are never web-reachable by themselves.

## Common Use Cases

- **Personal calendar sync** — one private URL for iPhone + Android + laptop; events propagate in seconds.
- **Family shared calendars** — create a Baïkal user per family member in the admin panel and share calendars.
- **Team/agency contact books** — a shared CardDAV address book that stays in sync across every phone.
- **Replace Google Contacts/Calendar** — keep the native apps, change where the data lives.

### Connecting your devices

| Client | Where | URL / settings |
|---|---|---|
| iOS / iPadOS (calendar) | Settings → Apps → Calendar → Calendar Accounts → Add Account → Other → CalDAV | Server: `<domain>`, User: your Baïkal user, Password: its password |
| iOS / iPadOS (contacts) | Same path → CardDAV | Same server/user/password |
| Android | [DAVx⁵](https://www.davx5.com/) → `+` → Login URL | `https://<domain>/` (auto-discovery) or `https://<domain>/dav.php/` |
| Thunderbird (calendar) | Calendar tab → New Calendar → On the Network | `https://<domain>/cal.php/` |
| Thunderbird (contacts) | CardBook add-on → New Address Book → CardDAV | `https://<domain>/card.php/` |

## Dependencies for

Almost none by design — the template is self-contained.

### Deployment Dependencies

- A Railway account (Hobby plan is sufficient; roughly **$5/month** for this service + volume).
- No external database — Baïkal uses SQLite stored on the volume.
- No deploy-form inputs: `BAIKAL_SERVERNAME` is auto-filled as `${{RAILWAY_PUBLIC_DOMAIN}}`.
- **Image-lag note:** the pinned `ckulka/baikal` image packages Baïkal 0.10.1; upstream Baïkal is at 0.12.1 (which includes an XSS fix) and the image maintainer had not published 0.11/0.12 tags when this template was verified. Bumping is a one-line change to the Dockerfile when a new tag lands.
- **Troubleshooting:** 404 on `/Specific/...` is expected (the database directory is blocked on purpose); if a client can't connect, check the URL ends in `.php/` and try `https://<domain>/dav.php/`; the admin panel user (`admin`) is separate from sync users — create a user for your devices.
