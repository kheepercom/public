#!/bin/bash
set -euo pipefail

LEGO_PATH=/var/lib/lego
PG_DATA=/var/lib/pgsql/data
EMAIL=noreply@kheeper.com

mkdir -p "$LEGO_PATH"

if [ -n "${DOMAIN_NAME:-}" ]; then
	target="$DOMAIN_NAME"
	san_entry="DNS:${target}"
else
	target=$(curl -fsS --retry 3 https://ifconfig.co)
	san_entry="IP Address:${target}"
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

if [ -n "${DOMAIN_NAME:-}" ]; then
	target_args=(--domains "$target")
	profile_args=()
else
	# Let's Encrypt rejects IPs in the CSR Common Name, so build a CSR
	# with an empty subject and the IP only in subjectAltName.
	install -d -m 700 "$LEGO_PATH/csr"
	key="$LEGO_PATH/csr/${target}.key"
	csr="$LEGO_PATH/csr/${target}.csr"
	openssl req -new -newkey rsa:2048 -nodes \
		-keyout "$key" -out "$csr" \
		-subj "/" \
		-addext "subjectAltName=IP:${target}"
	target_args=(--csr "$csr")
	profile_args=(--profile shortlived)
fi

echo "$target" > "$LEGO_PATH/issued-target"

exec /usr/local/bin/lego \
	--accept-tos \
	--email "$EMAIL" \
	--path "$LEGO_PATH" \
	--http \
	"${target_args[@]}" \
	run \
	"${profile_args[@]}" \
	--run-hook /usr/local/sbin/postgres-cert-deploy
