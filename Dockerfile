# Baïkal (CalDAV/CardDAV server) on Railway.
#
# Pinned to ckulka/baikal 0.10.1 nginx variant — the newest VERSIONED tag of
# the de facto standard Baïkal image (upstream Baïkal ships no official image
# and points at this one). The moving tags (latest tracks Apache builds,
# nginx is an unversioned rebuild) are rejected on purpose: the version pin
# keeps this template reproducible.
#
# NOTE (image lag): upstream Baïkal is 0.12.1 (2026-08-05); ckulka/baikal has
# no 0.11/0.12 tags published yet. Bumping later = change the tag below.
#
# Upstream image facts (verified from ckulka/baikal-docker @ 0.10.1):
#   - nginx variant listens on port 80 only (no TLS inside; Railway's edge
#     terminates HTTPS for your domain)
#   - all persistent data lives in /var/www/baikal/Specific (SQLite database
#     + wizard-written config) and /var/www/baikal/config — both are mounted
#     as Railway volumes by this template
#   - on every boot the entrypoint script 40-fix-baikal-file-permissions.sh
#     runs as root and chowns /var/www/baikal to nginx:nginx (the opt-out
#     env BAIKAL_SKIP_CHOWN is intentionally NOT set)
#   - first boot serves the "Baïkal initialization wizard" at / : set an
#     admin password, keep the SQLite default, done — no other configuration
FROM ckulka/baikal:0.10.1-nginx
