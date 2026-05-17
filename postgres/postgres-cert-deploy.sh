#!/bin/bash
set -euo pipefail

PG_DATA=/var/lib/pgsql/data
LEGO_PATH=/var/lib/lego

# When lego is invoked with --csr (IP-cert path), it sets LEGO_CERT_KEY_PATH
# but never writes the key file, so fall back to the key we created alongside
# the CSR.
if [ -n "${LEGO_CERT_KEY_PATH:-}" ] && [ -f "$LEGO_CERT_KEY_PATH" ]; then
	key_src="$LEGO_CERT_KEY_PATH"
else
	target=$(cat "$LEGO_PATH/issued-target")
	key_src="$LEGO_PATH/csr/${target}.key"
fi

install -o postgres -g postgres -m 600 "$LEGO_CERT_PATH" "$PG_DATA/server.crt"
install -o postgres -g postgres -m 600 "$key_src" "$PG_DATA/server.key"
systemctl is-active --quiet postgresql.service && \
	systemctl reload postgresql.service || true
