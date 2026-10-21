# 🏢 VulnCorp Enterprise Testbed — Project Context & Workspace Summary

## 📌 Executive Summary
**VulnCorp Enterprise** is an intentionally vulnerable enterprise cybersecurity testbed and cyber range simulating an end-to-end corporate infrastructure. It is designed for hands-on penetration testing, red teaming, blue team detection engineering, and vulnerability scanning (Nessus / OpenVAS).

The lab spans **3 isolated network security zones** across **11 dedicated virtual machines (6× Debian 13, 4× Ubuntu 24, 1× Windows Server 2019 Active Directory)**.

---

## 🌐 Network Architecture & Security Zones

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                NETWORK ZONE ARCHITECTURE                               │
└────────────────────────────────────────────────────────────────────────────────────────┘

 🌐 DMZ Zone (10.10.10.0/24 — vboxnet0)
    • dmz-web01   (10.10.10.10) — Flask Web Portal, SQLi, Command Injection, File Upload
    • dmz-mail01  (10.10.10.20) — Postfix SMTP Open Relay, Dovecot Plaintext IMAP/POP3
    • dmz-ftp01   (10.10.10.30) — HOST: vsftpd 2.3.4 lab (CVE-2011-2523 :21/:6200), ProFTPD 1.3.5 mod_copy (CVE-2015-3306 :2121)

 🛡️ Restricted Zone (172.16.0.0/24 — vboxnet1)
    • rz-db01     (172.16.0.10) — MySQL (root/toor), PostgreSQL (COPY RCE), Redis (No Auth)
    • rz-vpn01    (172.16.0.20) — Flask VPN Admin (admin/admin), Path Traversal, Leaked .ovpn
    • rz-monitor01(172.16.0.30) — Nagios (nagiosadmin/nagios), SNMP Public Community String

 🏢 Internal Zone (192.168.1.0/24 — vboxnet2)
    • int-dc01    (192.168.1.10) — Windows Server 2019 AD DS, AS-REP, Kerberoasting, DCSync
    • int-erp01   (192.168.1.20) — Flask ERP (SQLi, IDOR records, SSRF document importer)
    • int-dev01   (192.168.1.30) — GitLab (CVE-2021-22205), Jenkins (No Auth), Docker API :2375
    • int-files01 (192.168.1.40) — Samba SMBv1 (EternalBlue), Guest Shares, NFS no_root_squash
    • int-backup01(192.168.1.50) — rsync daemon (No Auth dump), Writable Cron PrivEsc
```

---

## 📂 Workspace Folder Structure & Inventory

```text
webserver/
├── README.md                          # Main project guide + CVE / Scanner detection matrix
├── CONTEXT.md                         # Full workspace context & summary (this file)
├── BUILD_GUIDE.md                     # Step-by-step 11-VM build, VirtualBox & network guide
├── KALI_ATTACK_GUIDE.md               # Attacker walkthrough with exact commands & tools
├── DEPLOYMENT_AND_USAGE_GUIDE.md      # Deployment instructions & container lifecycle
├── masterplan.md                      # Original comprehensive lab architecture & flag list
├── Dockerfile                         # Machine 1 (dmz-web01) container build
├── docker-compose.yml                 # Machine 1 container orchestration
├── deploy.sh                          # Machine 1 one-command deployment script
├── entrypoint.sh                      # Machine 1 service startup entrypoint
├── tunnel.sh                          # ngrok tunnel manager for remote lab access
├── app/                               # Machine 1 Flask web application
│   ├── app.py                         # Vulnerable Flask app (SQLi, cmd injection, upload, IDOR)
│   ├── static/                        # CSS styles, images, and leaked docs
│   └── templates/                     # Jinja2 templates (login, dashboard, nettools, etc.)
├── setup/                             # Machine 1 native setup scripts
│   ├── setup_privesc.sh               # Compiles SUID vuln-backup, writable cron, sudo find/vim
│   ├── setup_services.sh              # Configures OpenSSH weak auth, vsftpd anonymous access
│   └── setup_breadcrumbs.sh           # Plants DB configs, SSH keys for db01, user & root flags
└── machines/                          # Standalone deployment packages for Machines 2 to 11
    ├── README.md                      # Master directory of all machine deployment packages
    ├── dmz-mail01/                    # Machine 2: Postfix, Dovecot, Open Relay, Mailboxes
    ├── dmz-ftp01/                     # Machine 3: HOST docker-less (CVE-2011-2523 + CVE-2015-3306)
    ├── rz-db01/                       # Machine 4: MySQL 8, PostgreSQL 16, Redis Server
    ├── rz-vpn01/                      # Machine 5: Flask VPN Admin Portal, Path Traversal
    ├── rz-monitor01/                  # Machine 6: Nagios 4 Core, SNMPD Daemon
    ├── int-dc01/                      # Machine 7: Windows Server 2019 PowerShell AD Automation
    ├── int-erp01/                     # Machine 8: Flask ERP App, PostgreSQL Backend
    ├── int-dev01/                     # Machine 9: GitLab 14.0.12, Jenkins, Docker TCP :2375
    ├── int-files01/                   # Machine 10: Samba SMBv1, NFS Kernel Server
    └── int-backup01/                  # Machine 11: rsync daemon without authentication, Cron
```

---

## 🎯 Complete Machine Deployment Summary

| # | Machine Name | Hostname | OS | IP | Key Services & Ports | Deployment Method |
|---|--------------|----------|----|----|----------------------|-------------------|
| 1 | `dmz-web01` | `vulncorp-web01` | Debian 13 | `10.10.10.10` | HTTP `80`, SSH `22`, FTP `21` | `sudo ./deploy.sh` |
| 2 | `dmz-mail01` | `vulncorp-mail01` | Debian 13 | `10.10.10.20` | SMTP `25`, POP3 `110`, IMAP `143`, SSH `22` | `cd machines/dmz-mail01 && sudo ./deploy.sh` |
| 3 | `dmz-ftp01` | `vulncorp-ftp01` | Debian 13 | `10.10.10.30` | FTP `21`, ProFTPD `2121`, HTTP `80`, SSH `22`| `cd machines/dmz-ftp01 && sudo ./deploy.sh` |
| 4 | `rz-db01` | `vulncorp-db01` | Ubuntu 24 | `172.16.0.10` | MySQL `3306`, Postgres `5432`, Redis `6379` | `cd machines/rz-db01 && sudo ./deploy.sh` |
| 5 | `rz-vpn01` | `vulncorp-vpn01` | Ubuntu 24 | `172.16.0.20` | Web Admin `8443`, SSH `22` | `cd machines/rz-vpn01 && sudo ./deploy.sh` |
| 6 | `rz-monitor01` | `vulncorp-monitor01`| Debian 13 | `172.16.0.30` | Nagios `80`, SNMP `161/udp`, SSH `22` | `cd machines/rz-monitor01 && sudo ./deploy.sh` |
| 7 | `int-dc01` | `VULNCORP-DC01` | Win 2019 | `192.168.1.10` | Kerberos `88`, LDAP `389`, SMB `445`, RDP `3389`| `PowerShell: .\deploy_dc.ps1` |
| 8 | `int-erp01` | `vulncorp-erp01` | Ubuntu 24 | `192.168.1.20` | Flask ERP `80`, Postgres `5432`, SSH `22` | `cd machines/int-erp01 && sudo ./deploy.sh` |
| 9 | `int-dev01` | `vulncorp-dev01` | Ubuntu 24 | `192.168.1.30` | GitLab `80`, Jenkins `8080`, Docker `2375` | `cd machines/int-dev01 && sudo ./deploy.sh` |
| 10| `int-files01` | `VULNCORP-FILES01`| Debian 13 | `192.168.1.40` | SMB `445`, NetBIOS `139`, NFS `2049`, SSH `22`| `cd machines/int-files01 && sudo ./deploy.sh` |
| 11| `int-backup01`| `vulncorp-backup01`| Debian 13 | `192.168.1.50` | rsync `873`, SSH `22` | `cd machines/int-backup01 && sudo ./deploy.sh` |

---

## 🛡️ Vulnerability, CVE & Scanner Detection Summary

- **Software CVEs:**
  - **GitLab CE RCE:** `CVE-2021-22205` (Critical 10.0) — Nessus Plugin 154774
  - **ProFTPD mod_copy RCE:** `CVE-2015-3306` (Critical 9.8) — Nessus Plugin 83073
  - **PostgreSQL COPY PROGRAM RCE:** `CVE-2019-9193` (Critical 9.8) — Nessus Plugin 124318
  - **Samba SMBv1 / EternalBlue:** `CVE-2017-0144` (Critical 9.8) — Nessus Plugin 97833
  - **PrintNightmare (Windows DC):** `CVE-2021-34527` (Critical 9.8) — Nessus Plugin 151214
  - **GPP cPassword SYSVOL:** `CVE-2014-1812` (MS14-025, High 8.5) — Nessus Plugin 74249
  - **SMTP Open Relay:** `CVE-1999-0512` (High 7.5) — Nessus Plugin 10262
  - **NFS no_root_squash:** `CVE-1999-0554` (High 7.5) — Nessus Plugin 11356
  - **MySQL Default Accounts:** `CVE-1999-0502` (Critical 9.8) — Nessus Plugin 10452
  - **SNMP Default Public String:** `CVE-1999-0517` (High 7.5) — Nessus Plugin 41028
  - **rsync Unauthenticated Daemon:** `CVE-1999-0504` (High 7.5) — Nessus Plugin 10761

- **Web Application Flaws (OWASP Top 10 / DAST):**
  - SQL Injection (`/login`, `/erp/login`) — CWE-89
  - Remote Command Execution (`/nettools`) — CWE-78
  - Unrestricted File Upload (`/upload`) — CWE-434
  - Insecure Direct Object References (`/erp/records?id=1`) — CWE-639
  - Server-Side Request Forgery (`/erp/import?url=...`) — CWE-918
  - Directory / Path Traversal (`/viewer?file=...`, `/download/..%2f`) — CWE-22
  - Stored Cross-Site Scripting (`/notes`) — CWE-79

---

## 🧗‍♂️ Privilege Escalation & Lateral Movement Chain

1. **Foothold:** Exploit web vulnerabilities on `dmz-web01` (`10.10.10.10`) to gain a reverse shell as `webuser`.
2. **Local PrivEsc:** Use SUID PATH hijack `/usr/local/bin/vuln-backup` or writable `/opt/scripts/cleanup.sh` to obtain root.
3. **Pivoting to Restricted Zone:** Use harvested credentials from `/root/notes.txt` and `/opt/vulncorp/config/database.yml` to authenticate to `rz-db01` (`172.16.0.10:3306`).
4. **Credential Harvesting:** Dump `vulncorp_prod.internal_credentials` to extract Domain Admin, ERP, DevOps, and Backup credentials.
5. **Pivoting to Internal Zone:** Exfiltrate unauthenticated backups from `int-backup01` (`192.168.1.50:873`) and exploit unauthenticated Docker API on `int-dev01` (`192.168.1.30:2375`).
6. **Active Directory Takeover:** AS-REP Roast `svc_backup` on `int-dc01` (`192.168.1.10`), crack hash, execute DCSync via Impacket `secretsdump.py`, and pass-the-hash to achieve full Domain Admin dominance.
