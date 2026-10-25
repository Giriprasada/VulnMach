#!/bin/bash
# Start int-dev01 using this host's current address. DHCP can change it;
# run this again after the address changes so GitLab's external_url follows.
set -euo pipefail
cd "$(dirname "$0")"

HOST_IP="$(ip -4 route get 1.1.1.1 | awk '{for (i = 1; i <= NF; i++) if ($i == "src") {print $(i + 1); exit}}')"
if [ -z "${HOST_IP}" ]; then
  echo "Could not detect this host's IPv4 address." >&2
  exit 1
fi

umask 077
printf 'HOST_IP=%s\n' "${HOST_IP}" > .env
echo "GitLab external_url will be http://${HOST_IP}"
docker compose up -d --build
