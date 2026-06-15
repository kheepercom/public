#!/bin/bash
# Append hostssl pg_hba.conf rules so each configured app user (one with a
# password) can connect over TLS from anywhere. Idempotent: each user's rule is
# guarded by a marker. Runs as the postgres user; reloads only on change.
set -euo pipefail

PGDATA=/var/lib/pgsql/data
HBA="$PGDATA/pg_hba.conf"
reload=0

for u in ${POSTGRES_REMOTE_USERS:-}; do
	marker="# kheeper remote app-user $u rule"
	if ! grep -qF "$marker" "$HBA"; then
		{
			echo
			echo "$marker"
			echo "hostssl all $u 0.0.0.0/0 scram-sha-256"
			echo "hostssl all $u ::/0      scram-sha-256"
		} >> "$HBA"
		reload=1
	fi
done

if [ "$reload" = 1 ]; then
	pg_ctl reload -D "$PGDATA"
fi
