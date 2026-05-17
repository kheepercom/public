#!/usr/bin/env bash
# Apply firewalld runtime rich rules from a CIDR allowlist file.
# One CIDR per line. Blank lines and lines starting with # are ignored.
# Re-running is idempotent because runtime rules reset on each firewalld start.

set -euo pipefail

allowlist="${1:?usage: pihole-firewall.sh <allowlist-file>}"

if [[ ! -r "$allowlist" ]]; then
	echo "pihole-firewall: allowlist file not readable: $allowlist" >&2
	exit 1
fi

while IFS= read -r line || [[ -n "$line" ]]; do
	cidr="${line%%#*}"
	cidr="${cidr#"${cidr%%[![:space:]]*}"}"
	cidr="${cidr%"${cidr##*[![:space:]]}"}"
	[[ -z "$cidr" ]] && continue

	if [[ "$cidr" == *:* ]]; then
		family="ipv6"
	else
		family="ipv4"
	fi

	for proto in tcp udp; do
		firewall-cmd --zone=public --add-rich-rule="rule family=\"$family\" source address=\"$cidr\" port port=\"53\" protocol=\"$proto\" accept"
	done
done < "$allowlist"
