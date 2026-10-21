#!/bin/bash
# ================================================================
# VulnCorp - Machine 3: dmz-ftp01
# Prefers OFFLINE pack when offline/proftpd tarball exists.
#   sudo ./deploy.sh              # auto: offline if ready, else online
#   sudo ./deploy-offline.sh      # force offline
#   sudo ./prepare-offline.sh     # build offline/ on an online box
# ================================================================
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo ./deploy.sh" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"
chmod +x ./*.sh setup/*.sh files/vsftpd-234-lab.py 2>/dev/null || true

TGZ="$ROOT_DIR/offline/proftpd-1.3.5-linux-amd64.tar.gz"
if [[ -f "$TGZ" ]]; then
  echo "[*] offline/proftpd tarball found — using OFFLINE deploy"
  exec bash "$ROOT_DIR/deploy-offline.sh"
fi

echo "============================================="
echo "  VulnCorp dmz-ftp01 - ONLINE HOST deploy"
echo "  (no offline pack found; needs internet)"
echo "============================================="
echo "  Tip: on an online box run: sudo ./prepare-offline.sh"
echo "       then copy machines/dmz-ftp01/ to the lab VM."
echo "============================================="

if command -v docker >/dev/null 2>&1; then
  docker stop vulncorp-ftp01 2>/dev/null || true
fi

bash setup/install_proftpd_135.sh
bash setup/setup_host_services.sh
bash setup/setup_breadcrumbs.sh

echo
ss -lntp | grep -E ':21 |:2121|:80 |:6200' || true
echo
echo "ONLINE deploy done. To make an offline pack from this host:"
echo "  sudo ./prepare-offline.sh"