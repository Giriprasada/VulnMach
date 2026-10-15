#!/bin/bash
# Image build only. Passwords are applied at container start from the environment.
set -euo pipefail

echo "[+] MySQL will listen on all interfaces..."
sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

echo "[+] Configuring SSH..."
mkdir -p /var/run/sshd /root/.ssh
chmod 755 /var/run/sshd
cat > /etc/ssh/sshd_config << 'EOF'
Port 22
PermitRootLogin yes
PasswordAuthentication yes
MaxAuthTries 10
UsePAM yes
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

echo "[+] Planting flags..."
echo "VULN{pii_d4t4_3xfil}" > /tmp/pii_flag.txt
echo "VULN{db_s3rv3r_r00t3d_m4ch1n3_4}" > /root/root.txt
chmod 600 /root/root.txt

echo "[+] Image setup complete. MySQL data is loaded on first start."
