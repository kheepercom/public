#!/usr/bin/env bash
set -euo pipefail

CONF=/etc/forgejo/app.ini
WORK=/var/lib/forgejo

# Operator config: domain + admin bootstrap fields.
# shellcheck disable=SC1091
. /etc/kheeper/forgejo.env

# Inject operator-supplied values into [server] each boot so config.json edits
# to `domain` propagate. Forgejo's FORGEJO__SECTION__KEY env override doesn't
# apply for these fields at startup, so we write them into app.ini directly.
# Forgejo's own secret generation (SECRET_KEY, INTERNAL_TOKEN, JWT_SECRET,
# LFS_JWT_SECRET) also persists to app.ini, which is why /etc/forgejo is
# writable by the git group.
set_ini() {
	local key=$1 val=$2
	if grep -qE "^${key} " "$CONF"; then
		sed -i "s|^${key} .*|${key} = ${val}|" "$CONF"
	else
		sed -i "/^\[server\]$/a ${key} = ${val}" "$CONF"
	fi
}

set_ini DOMAIN     "$FORGEJO_DOMAIN"
set_ini ROOT_URL   "https://${FORGEJO_DOMAIN}/"
set_ini SSH_DOMAIN "$FORGEJO_DOMAIN"

# Schema migrations. Idempotent. Also triggers Forgejo's auto-save of
# SECRET_KEY + INTERNAL_TOKEN into app.ini if missing.
/usr/local/bin/forgejo -c "$CONF" -w "$WORK" migrate

# Create the admin user if absent. `forgejo admin user list` exits 0 with a
# header line plus one row per user; we match the username column.
if ! /usr/local/bin/forgejo -c "$CONF" -w "$WORK" admin user list \
	| awk 'NR>1 {print $2}' | grep -Fxq "$FORGEJO_ADMIN_USERNAME"; then
	/usr/local/bin/forgejo -c "$CONF" -w "$WORK" admin user create \
		--admin \
		--username "$FORGEJO_ADMIN_USERNAME" \
		--password "$FORGEJO_ADMIN_PASSWORD" \
		--email    "$FORGEJO_ADMIN_EMAIL"
fi
