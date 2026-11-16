#!/bin/bash
# ================================================================
# VulnCorp dmz-ftp01 — single host deploy
#
# One entry point for every lab service:
#   :21   vsftpd 2.3.4 lab stub   CVE-2011-2523 (backdoor on :6200)
#   :2121 ProFTPD 1.3.5 + mod_copy CVE-2015-3306
#   :80   Apache DocumentRoot /var/www/html
#   :22   OpenSSH lab login + Terrapin algorithm drop
#
# Offline pack present  -> deploy-offline.sh (no internet)
# Otherwise             -> apt + ProFTPD 1.3.5 source build
#
# Usage:
#   cd machines/dmz-ftp01
#   sudo ./deploy.sh
# ================================================================
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo ./deploy.sh" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TGZ="$ROOT_DIR/offline/proftpd-1.3.5-linux-amd64.tar.gz"

chmod +x "$ROOT_DIR"/*.sh "$ROOT_DIR"/setup/*.sh 2>/dev/null || true

if [[ -f "$TGZ" ]]; then
  echo "[+] Offline pack found — installing without internet"
  exec bash "$ROOT_DIR/deploy-offline.sh"
fi

echo "[+] No offline pack — online install (needs internet)"
bash "$ROOT_DIR/setup/setup_host_services.sh"
bash "$ROOT_DIR/setup/install_proftpd_135.sh"
bash "$ROOT_DIR/setup/setup_breadcrumbs.sh"

systemctl daemon-reload
systemctl enable --now proftpd-lab.service
systemctl restart vsftpd-234-lab.service apache2 || true

echo
echo "============================================="
echo "  ONLINE deploy complete (host systemd)"
echo "  :21   vsftpd-234-lab  CVE-2011-2523"
echo "  :2121 ProFTPD 1.3.5   CVE-2015-3306"
echo "  :80   Apache /var/www/html"
echo "  Optional check: sudo ./setup/verify_lab.sh"
echo "============================================="