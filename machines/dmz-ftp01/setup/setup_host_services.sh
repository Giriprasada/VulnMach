#!/bin/bash
# Configure host services for dmz-ftp01 (docker-less).
# Run as root from machines/dmz-ftp01/
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FILES="$ROOT_DIR/files"

echo "[+] Installing host packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq apache2 openssh-server python3 curl wget net-tools \
  ftp libcap2-bin

# Distro vsftpd cannot provide CVE-2011-2523; install but keep disabled.
apt-get install -y -qq vsftpd || true
systemctl stop vsftpd 2>/dev/null || true
systemctl disable vsftpd 2>/dev/null || true

# Do not use package proftpd — lab uses /opt/proftpd-1.3.5
systemctl stop proftpd 2>/dev/null || true
systemctl disable proftpd 2>/dev/null || true

id ftpuser >/dev/null 2>&1 || useradd -m -s /bin/bash ftpuser
echo "ftpuser:ftp123" | chpasswd

mkdir -p /var/ftp/pub/keys /var/www/html /opt/proftpd-1.3.5/etc /opt/proftpd-1.3.5/var
chmod -R 777 /var/ftp

echo "[+] Installing vsftpd 2.3.4 lab stub (port 21, CVE-2011-2523)..."
install -m 755 "$FILES/vsftpd-234-lab.py" /usr/local/sbin/vsftpd-234-lab.py
install -m 644 "$FILES/vsftpd-234-lab.service" /etc/systemd/system/vsftpd-234-lab.service

echo "[+] Installing ProFTPD lab config (port 2121, CVE-2015-3306)..."
install -m 644 "$FILES/proftpd.conf" /opt/proftpd-1.3.5/etc/proftpd.conf
install -m 644 "$FILES/proftpd-lab.service" /etc/systemd/system/proftpd-lab.service

echo "[+] Configuring Apache DocumentRoot /var/www/html..."
install -m 644 "$FILES/apache-proftpd-lab.conf" /etc/apache2/sites-available/proftpd-lab.conf
a2dissite 000-default.conf 2>/dev/null || true
a2ensite proftpd-lab.conf
# Seed default index if missing
[[ -f /var/www/html/index.html ]] || echo '<html><body>VulnCorp FTP Lab</body></html>' > /var/www/html/index.html

# Weak SSH for lab (keep host login working + banner exposed)
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

systemctl daemon-reload
apache2ctl configtest
systemctl enable --now apache2
systemctl enable --now vsftpd-234-lab.service
systemctl enable --now proftpd-lab.service
systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true

echo "[+] Host services configured"
