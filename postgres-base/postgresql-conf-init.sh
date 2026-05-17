#!/bin/bash
# Append snippets from /etc/kheeper/postgresql-conf.d/*.conf to postgresql.conf
# in alphabetical order, each guarded by a per-file marker so re-runs (and
# re-application after a pg_basebackup restore) are no-ops. Layered images
# can drop their own files in the same dir; numeric prefixes set ordering, so
# later snippets override earlier ones for duplicate settings.
set -euo pipefail

CONF=/var/lib/pgsql/data/postgresql.conf
SNIPPET_DIR=/etc/kheeper/postgresql-conf.d

shopt -s nullglob
for snippet in "$SNIPPET_DIR"/*.conf; do
	marker="# $(basename "$snippet") appended to postgresql.conf"
	if grep -qF "$marker" "$CONF" 2>/dev/null; then
		continue
	fi
	{
		echo
		echo "$marker"
		cat "$snippet"
	} >> "$CONF"
done
