#!/bin/bash
# setup_breadcrumbs.sh — Plant sensitive files in FTP pub share
set -e

echo "[+] Planting sensitive files in FTP pub..."

cat > /var/ftp/pub/network_map.txt << 'EOF'
VulnCorp Internal Network Map
==============================
DMZ Zone:         10.10.10.0/24
  Web Server:     10.10.10.10   (HTTP 80, SSH 22, FTP 21)
  Mail Server:    10.10.10.20   (SMTP 25, IMAP 143, HTTP 80)
  FTP Server:     10.10.10.30   (FTP 21, ProFTPD 2121)

Restricted Zone:  172.16.0.0/24
  Database:       172.16.0.10   (MySQL 3306, PostgreSQL 5432, Redis 6379)
  VPN:            172.16.0.20   (VPN Admin 8443)
  Monitoring:     172.16.0.30   (Nagios 80, SNMP 161)

Internal Zone:    192.168.1.0/24
  Domain Ctrl:    192.168.1.10  (RDP 3389, LDAP 389)
  ERP Server:     192.168.1.20  (HTTP 80)
  Dev Server:     192.168.1.30  (GitLab 80, Jenkins 8080, Docker 2375)
  File Server:    192.168.1.40  (SMB 445, NFS 2049)
  Backup Server:  192.168.1.50  (rsync 873)

Credentials: See web portal or IT share on 192.168.1.40
EOF

# Partial DB credentials (breadcrumb)
cat > /var/ftp/pub/db_credentials.txt << 'EOF'
[PARTIAL BACKUP — IT TEAM USE ONLY]
MySQL Production:
  Host: 172.16.0.10
  User: root
  Password: t**r   (ask sysadmin)

Redis:
  Host: 172.16.0.10:6379
  Auth: (none — to be fixed)
EOF

# Employee list for password spraying
cat > /var/ftp/pub/employee_list.csv << 'EOF'
FirstName,LastName,Username,Department
John,Doe,john.doe,IT
Jane,Smith,jane.smith,Development
Admin,User,admin,IT
Sys,Admin,sysadmin,IT
Help,Desk,helpdesk,Support
Backup,Agent,svc_backup,IT
EOF

# Leaked SSH private key
ssh-keygen -t rsa -b 2048 -f /var/ftp/pub/keys/backup_rsa -N "" -C "sysadmin@vulncorp.local" -q

# Flags
echo "VULN{anon_ftp_wr1t3}"                    > /var/ftp/pub/flag1.txt
echo "VULN{ssh_k3y_l3ak3d}"                    > /var/ftp/pub/keys/flag.txt
echo "VULN{ftp_s3rv3r_r00t3d_m4ch1n3_3}"       > /root/root.txt
chmod -R a+rX /var/ftp
chown -R www-data:www-data /var/ftp 2>/dev/null || chown -R ftp:ftp /var/ftp 2>/dev/null || true

echo "[+] FTP breadcrumbs planted on host at /var/ftp/pub/"
