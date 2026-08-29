#!/bin/bash
set -euo pipefail

PG_DATA=/var/lib/pgsql/data

install -o postgres -g postgres -m 600 "$LEGO_HOOK_CERT_PATH" "$PG_DATA/server.crt"
install -o postgres -g postgres -m 600 "$LEGO_HOOK_CERT_KEY_PATH" "$PG_DATA/server.key"
systemctl is-active --quiet postgresql.service && \
	systemctl reload postgresql.service || true
