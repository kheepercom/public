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

# v5 folded `renew` into `run`; it renews when the stored cert is due and is a
# no-op otherwise. ARI can also pull the renewal earlier than --renew-days.
exec /usr/local/bin/lego run \
	--accept-tos \
	--email "$EMAIL" \
	--path "$LEGO_PATH" \
	--http \
	--domains "$target" \
	"${profile_args[@]}" \
	--renew-days "$days" \
	--deploy-hook /usr/local/sbin/postgres-cert-deploy
