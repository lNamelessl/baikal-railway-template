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
#     + wizard-written config) and /var/www/baikal/config — Railway attaches
#     ONE volume per service, so this template mounts a single volume over
#     /var/www/baikal and seeds it on first boot (see railway-entrypoint.sh:
#     first boot copies the app tree onto the volume; later boots refresh the
#     app code while preserving Specific/ and config/)
#   - on every boot the entrypoint script 40-fix-baikal-file-permissions.sh
#     runs as root and chowns /var/www/baikal to nginx:nginx (the opt-out
#     env BAIKAL_SKIP_CHOWN is intentionally NOT set)
#   - first boot serves the "Baïkal initialization wizard" at / : set an
#     admin password, keep the SQLite default, done — no other configuration
FROM ckulka/baikal:0.10.1-nginx

# Stash the image's Baikal tree so the single Railway volume (mounted over
# /var/www/baikal) can be seeded on first boot and code-refreshed later.
RUN cp -a /var/www/baikal /opt/baikal-pristine

COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod 755 /usr/local/bin/railway-entrypoint.sh

# CMD is the nginx base image default, spelled out explicitly so the build
# pipeline can never drop it when the ENTRYPOINT is overridden; the wrapper
# execs the stock /docker-entrypoint.sh, so nothing else changes.
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
