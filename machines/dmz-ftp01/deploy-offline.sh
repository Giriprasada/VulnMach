#!/bin/bash
# ================================================================
# VulnCorp dmz-ftp01 — OFFLINE host install (no internet)
#
# Prerequisites: machines/dmz-ftp01/offline/ populated by
#   sudo ./prepare-offline.sh  (on an online Debian amd64 box)
#
# Usage on air-gapped VM:
#   cd machines/dmz-ftp01
#   sudo ./deploy-offline.sh
# ================================================================
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo ./deploy-offline.sh" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
OFF="$ROOT_DIR/offline"
DEB="$OFF/debs"
FILES="$ROOT_DIR/files"
TGZ="$OFF/proftpd-1.3.5-linux-amd64.tar.gz"

echo "============================================="
echo "  VulnCorp dmz-ftp01 - OFFLINE HOST deploy"
echo "============================================="

if [[ ! -f "$TGZ" ]]; then
  echo "[-] Missing $TGZ" >&2
  echo "    Run prepare-offline.sh on an online machine first," >&2
  echo "    then copy the whole dmz-ftp01/ folder here." >&2
  exit 1
fi

if [[ ! -d "$DEB" ]] || ! ls "$DEB"/*.deb >/dev/null 2>&1; then
  echo "[!] WARNING: offline/debs has no .deb files."
  echo "    Will continue with bundled ProFTPD + configs only."
  echo "    Apache/python must already be installed on this host."
fi

# Stop docker leftover / online units that may hold ports
if command -v docker >/dev/null 2>&1; then
  docker stop vulncorp-ftp01 2>/dev/null || true
fi
systemctl stop vsftpd 2>/dev/null || true
systemctl disable vsftpd 2>/dev/null || true
systemctl stop proftpd 2>/dev/null || true

echo "[+] Installing local .deb packages (no apt update)..."
if ls "$DEB"/*.deb >/dev/null 2>&1; then
  # Multiple passes help resolve ordering without network
  set +e
  for _ in 1 2 3; do
    dpkg -i "$DEB"/*.deb
  done
  # Fix configure state without fetching anything
  dpkg --configure -a
  set -e
fi

echo "[+] Installing ProFTPD 1.3.5 from offline tarball -> /opt/proftpd-1.3.5"
mkdir -p /opt
tar -C /opt -xzf "$TGZ"
chmod +x /opt/proftpd-1.3.5/sbin/proftpd
mkdir -p /opt/proftpd-1.3.5/etc /opt/proftpd-1.3.5/var
touch /var/log/proftpd-lab.log

echo "[+] Installing lab configs and systemd units from files/"
install -m 755 "$FILES/vsftpd-234-lab.py" /usr/local/sbin/vsftpd-234-lab.py
install -m 644 "$FILES/vsftpd-234-lab.service" /etc/systemd/system/vsftpd-234-lab.service
install -m 644 "$FILES/proftpd.conf" /opt/proftpd-1.3.5/etc/proftpd.conf
install -m 644 "$FILES/proftpd-lab.service" /etc/systemd/system/proftpd-lab.service
install -m 644 "$FILES/apache-proftpd-lab.conf" /etc/apache2/sites-available/proftpd-lab.conf

id ftpuser >/dev/null 2>&1 || useradd -m -s /bin/bash ftpuser
echo "ftpuser:ftp123" | chpasswd

mkdir -p /var/ftp/pub/keys /var/www/html
chmod -R 777 /var/ftp
[[ -f /var/www/html/index.html ]] || echo '<html><body>VulnCorp FTP Lab</body></html>' > /var/www/html/index.html

if command -v a2ensite >/dev/null 2>&1; then
  a2dissite 000-default.conf 2>/dev/null || true
  a2ensite proftpd-lab.conf
fi

mkdir -p /etc/ssh/sshd_config.d
cat > /etc/ssh/banner.txt << 'EOF'
*************************************************************
*  VulnCorp Internal Server — vulncorp-ftp01                *
*  Authorized access only. All sessions are logged.         *
*  Contact: it-support@vulncorp.local                       *
*  Server: Debian 13 (Trixie)                               *
*************************************************************
EOF

cat > /etc/ssh/sshd_config.d/99-vulncorp-lab.conf << 'EOF'
PermitRootLogin yes
PasswordAuthentication yes
MaxAuthTries 10
Banner /etc/ssh/banner.txt
EOF

bash "$ROOT_DIR/setup/setup_breadcrumbs.sh"

systemctl daemon-reload
systemctl enable --now apache2 2>/dev/null || true
systemctl enable --now vsftpd-234-lab.service
systemctl enable --now proftpd-lab.service
systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true

echo
ss -lntp | grep -E ':21 |:2121|:80 |:6200' || true
echo
echo "============================================="
echo "  OFFLINE deploy complete (host systemd)"
echo "  :21   vsftpd-234-lab  CVE-2011-2523"
echo "  :2121 ProFTPD 1.3.5   CVE-2015-3306"
echo "  :80   Apache /var/www/html"
echo "  Optional check: sudo ./setup/verify_lab.sh"
echo "============================================="
