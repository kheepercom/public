#!/bin/bash
set -euo pipefail

LEGO_PATH=/var/lib/lego
PG_DATA=/var/lib/pgsql/data
EMAIL=noreply@kheeper.com

mkdir -p "$LEGO_PATH"

# lego v5 changed the on-disk layout and refuses to read a v4 one. `migrate`
# rewrites it in place, skips anything already migrated, and errors out if
# there is no certificates dir at all — so only run it on a host that has
# issued before. It prompts, hence the piped Y, and writes a suggested config
# file into the cwd, hence the subshell cd.
if [ -d "$LEGO_PATH/certificates" ]; then
	(cd "$LEGO_PATH" && echo Y | /usr/local/bin/lego migrate --path "$LEGO_PATH")
fi

if [ -n "${DOMAIN_NAME:-}" ]; then
	target="$DOMAIN_NAME"
	san_entry="DNS:${target}"
	profile_args=()
else
	target=$(curl -fsS --retry 3 https://ifconfig.co)
	san_entry="IP Address:${target}"
	# Let's Encrypt only issues IP certs under its short-lived (6-day) profile.
	profile_args=(--profile shortlived)
fi

# If the deployed cert already covers the desired target, skip re-issuance.
# A malformed or unreadable cert falls through and gets replaced.
if [ -f "$PG_DATA/server.crt" ] && \
	openssl x509 -in "$PG_DATA/server.crt" -noout -ext subjectAltName 2>/dev/null \
		| tail -n +2 | tr ',' '\n' \
		| sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
		| grep -Fxq "$san_entry"; then
	echo "existing cert already covers $target; skipping issuance"
	exit 0
fi

echo "$target" > "$LEGO_PATH/issued-target"

# An IP in --domains becomes an ACME `ip` identifier, and v5 leaves the common
# name empty by default, so lego builds the empty-subject/IP-SAN CSR itself.
#
# `run` obtains or renews as needed. We only get here when the deployed cert
# does not cover the target, so force it past the not-due-yet check, and skip
# the renewal jitter — this unit runs Before=postgresql.service at boot.
exec /usr/local/bin/lego run \
	--accept-tos \
	--email "$EMAIL" \
	--path "$LEGO_PATH" \
	--http \
	--domains "$target" \
	"${profile_args[@]}" \
	--renew-force \
	--no-random-sleep \
	--deploy-hook /usr/local/sbin/postgres-cert-deploy
