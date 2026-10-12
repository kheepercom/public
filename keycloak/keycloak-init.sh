#!/bin/bash
# Give the keycloak role a password on first boot, including on a host
# restored from another host's backup.
set -euo pipefail

ENV=/var/lib/keycloak/db.env
[ -s "$ENV" ] && exit 0

pw=$(head -c 32 /dev/urandom | base64 | tr -d '/+=')
runuser -u postgres -- psql -v ON_ERROR_STOP=1 -q -c "ALTER ROLE keycloak PASSWORD '$pw'"
install -o keycloak -g keycloak -m 0600 /dev/null "$ENV.tmp"
echo "KC_DB_PASSWORD=$pw" > "$ENV.tmp"
mv "$ENV.tmp" "$ENV"
