#!/usr/bin/env bash
set -euo pipefail

CONF=/etc/forgejo/app.ini
WORK=/var/lib/forgejo
RUNNER_STATE=/var/lib/act-runner/.runner
INSTANCE=http://127.0.0.1:3500

# Already registered: the .runner file holds this host's runner identity and
# token. Re-registering would create a duplicate runner in Forgejo, so bail.
if [[ -s "$RUNNER_STATE" ]]; then
	exit 0
fi

# `act_runner register` validates the token against the running instance (not
# just the DB), so wait for Forgejo's HTTP API to accept connections.
for _ in $(seq 1 60); do
	if curl -fsS "${INSTANCE}/api/healthz" >/dev/null 2>&1; then
		break
	fi
	sleep 1
done

# Mint a global runner registration token straight from the DB (no web UI
# needed). Runs as the git user that owns app.ini and holds the DB peer identity.
token="$(runuser -u git -- /usr/local/bin/forgejo -c "$CONF" -w "$WORK" \
	actions generate-runner-token)"

# Register as the unprivileged act-runner user so the .runner state and per-job
# workdirs are owned by it, not by git (which owns Forgejo's secrets).
runuser -u act-runner -- /usr/local/bin/act_runner register \
	--no-interactive \
	--instance "$INSTANCE" \
	--token "$token" \
	--name "$(hostname)" \
	--labels native:host \
	--config /etc/act-runner/config.yaml
