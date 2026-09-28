#!/bin/sh
# Railway boot wrapper for ckulka/baikal with ONE volume mounted at
# /var/www/baikal (Railway attaches a single volume per service; upstream
# suggests mounting Specific/ and config/ separately — both live under this
# one mount here, so the wizard-written SQLite DB and config both persist).
#
# A volume mounted over /var/www/baikal starts empty and would shadow the
# image's Baikal application files (html/, Core/, ...). This wrapper:
#   - first boot: copies the pristine Baikal tree from the image onto the
#     volume;
#   - later boots: refreshes the application code from the image so image
#     upgrades take effect, while PRESERVING the data directories written
#     by the wizard (Specific/ and config/).
# It then hands off to the stock nginx docker-entrypoint.sh, which runs the
# upstream /docker-entrypoint.d scripts (including the root chown of the
# whole tree to nginx:nginx) before starting nginx.
set -eu

PRISTINE=/opt/baikal-pristine
TARGET=/var/www/baikal

if [ ! -d "$TARGET/html" ]; then
  echo "railway-entrypoint: seeding $TARGET from pristine image copy"
  cp -a "$PRISTINE/." "$TARGET/"
else
  echo "railway-entrypoint: refreshing app code from image, preserving Specific/ and config/"
  for entry in "$PRISTINE"/* "$PRISTINE"/.[!.]*; do
    [ -e "$entry" ] || continue
    name=$(basename "$entry")
    [ "$name" = "Specific" ] && continue
    [ "$name" = "config" ] && continue
    rm -rf "$TARGET/$name"
    cp -a "$entry" "$TARGET/$name"
  done
fi

exec /docker-entrypoint.sh "$@"
