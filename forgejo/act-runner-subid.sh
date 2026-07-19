#!/usr/bin/env bash
set -euo pipefail

# Grant the unprivileged act-runner user a subordinate uid/gid range so rootless
# podman (used by CI workflows, e.g. testcontainers) can allocate a user
# namespace. Without this, `podman run` under the host executor fails with
# "no subuid ranges found for user act-runner".
#
# Written at boot, not build time: bootc drops build-time /etc writes during its
# 3-way /etc merge on a fresh host — the same reason the git and act-runner
# accounts are provisioned via sysusers.d rather than a build-time useradd.
# Idempotent: only appends the range if act-runner isn't already present.
#
# The range 589824..655359 sits immediately above the base image's fedora range
# (524288..589823) so the two never overlap.
start=589824
count=65536

for f in /etc/subuid /etc/subgid; do
	if ! grep -q '^act-runner:' "$f" 2>/dev/null; then
		printf 'act-runner:%d:%d\n' "$start" "$count" >>"$f"
	fi
done
