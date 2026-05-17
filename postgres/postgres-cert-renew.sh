#!/bin/bash
set -euo pipefail

LEGO_PATH=/var/lib/lego
EMAIL=noreply@kheeper.com

if [ ! -s "$LEGO_PATH/issued-target" ]; then
	echo "no recorded cert; nothing to renew"
	exit 0
fi
target=$(cat "$LEGO_PATH/issued-target")

# Detect IP (IPv4 dotted-quad or anything containing a colon, i.e. IPv6).
# IP certs use Let's Encrypt's shortlived (6-day) profile and renew at half-life.
if [[ "$target" =~ : ]] || [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	profile_args=(--profile shortlived)
	days=3
else
	profile_args=()
	days=30
fi

exec /usr/local/bin/lego \
	--accept-tos \
	--email "$EMAIL" \
	--path "$LEGO_PATH" \
	--http \
	--domains "$target" \
	renew \
	"${profile_args[@]}" \
	--days "$days" \
	--renew-hook /usr/local/sbin/postgres-cert-deploy
