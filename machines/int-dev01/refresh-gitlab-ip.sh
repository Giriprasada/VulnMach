#!/bin/bash
# If eth0's address changed, point GitLab at the new one and recreate that container.
set -euo pipefail
cd /opt/int-dev01

new_ip="$(ip -4 route get 1.1.1.1 | awk '{for (i = 1; i <= NF; i++) if ($i == "src") {print $(i + 1); exit}}')"
if [ -z "${new_ip}" ]; then
  echo "No IPv4 address on the default route yet." >&2
  exit 0
fi

old_ip=""
if [ -f .env ]; then
  old_ip="$(awk -F= '/^HOST_IP=/{print $2}' .env)"
fi
if [ "${new_ip}" = "${old_ip}" ]; then
  exit 0
fi

umask 077
printf 'HOST_IP=%s\n' "${new_ip}" > .env
echo "GitLab external_url updated to http://${new_ip}"
docker compose up -d --no-deps --force-recreate vulncorp-gitlab
