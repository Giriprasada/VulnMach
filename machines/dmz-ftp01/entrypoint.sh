#!/bin/bash
# LEGACY Docker entrypoint — prefer host: sudo ./deploy.sh
echo "============================================="
echo "  VulnCorp FTP Server (dmz-ftp01) LEGACY Docker"
echo "  Prefer HOST deploy: sudo ./deploy.sh"
echo "============================================="
echo "[*] Starting SSH..."
service ssh start || true
echo "[*] Starting Apache..."
service apache2 start || true
echo "[*] For CVE labs on the host, use systemd units:"
echo "      vsftpd-234-lab.service  (port 21 / 6200)"
echo "      proftpd-lab.service     (port 2121)"
echo "  EDUCATIONAL USE ONLY"
echo "============================================="
tail -f /dev/null
