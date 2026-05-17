#!/bin/bash
# Set the postgres superuser password from $POSTGRES_PASSWORD and ensure
# pg_hba.conf has a hostssl rule so external clients can authenticate over TLS.
# Idempotent: ALTER ROLE re-runs harmlessly, and the hba append is guarded by a
# marker so it only happens on first boot (or after a pg_basebackup restore
# that replaces pg_hba.conf).
set -euo pipefail

: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD must be set}"

PGDATA=/var/lib/pgsql/data
HBA="$PGDATA/pg_hba.conf"
MARKER="# kheeper postgres-password rule"

# psql's :'pw' variable substitution is a client-side feature and is only
# applied when psql parses the SQL itself — i.e. via stdin or -f, NOT -c.
# (`man psql`: "-c command ... must be ... completely parsable by the server,
# i.e., it contains no psql-specific features".)
psql -v ON_ERROR_STOP=1 -d postgres -v pw="$POSTGRES_PASSWORD" <<'SQL'
ALTER ROLE postgres PASSWORD :'pw';
SQL

if ! grep -qF "$MARKER" "$HBA"; then
	{
		echo
		echo "$MARKER"
		echo "hostssl all postgres 0.0.0.0/0 scram-sha-256"
		echo "hostssl all postgres ::/0      scram-sha-256"
	} >> "$HBA"
	pg_ctl reload -D "$PGDATA"
fi
