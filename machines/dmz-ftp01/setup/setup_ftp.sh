#!/bin/bash
# setup_ftp.sh — host FTP vulnerability configuration (docker-less).
# Prefer: sudo ./deploy.sh from machines/dmz-ftp01/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[+] dmz-ftp01 host FTP setup"
bash "$SCRIPT_DIR/install_proftpd_135.sh"
bash "$SCRIPT_DIR/setup_host_services.sh"
bash "$SCRIPT_DIR/setup_breadcrumbs.sh"

echo "[+] FTP service setup complete (host systemd)"
echo "    Port 21   = vsftpd-234-lab (CVE-2011-2523)"
echo "    Port 2121 = ProFTPD 1.3.5 mod_copy (CVE-2015-3306)"
echo "    Port 80   = Apache DocumentRoot /var/www/html"
