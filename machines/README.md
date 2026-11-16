# 🏢 VulnCorp Enterprise Lab — Machine Deployment Packages

> 📝 **IP Note:** All IP addresses listed below are defaults/placeholders. Change them to match your actual lab network layout in each machine's `docker-compose.yml` and `deploy.sh` (or `deploy_dc.ps1` / `deploy_ws.ps1` for Windows) before deploying.

Every machine in the VulnCorp Enterprise testbed is organized as a self-contained, deployable package with its own `Dockerfile`, `docker-compose.yml`, and `deploy.sh` (or `deploy_dc.ps1` / `deploy_ws.ps1` for Windows).

---

## 🗺️ Master Machine Index

ASPER Tool Testing Phase 1 pilot. Host OS and service versions below are the testbed spec. IPs stay lab placeholders.

| # | Folder | Spec instance | Zone | OS | Spec services |
|---|--------|---------------|------|----|---------------|
| — | *(workstation, not in this repo)* | Scan-Agent ×3 (DMZ, Internal, Restricted) | Zones 1–3 | Ubuntu 24.04 LTS | Docker Engine (latest), OpenVAS / GVM (latest). RAM 8–16 GB, disk 50–100 GB |
| 1 | `../` *(root)* | `dmzweb01` | DMZ | Ubuntu 24.04 LTS | Flask 3.0.x (Python 3.11.2+), vsftpd 3.0.5, OpenSSH 9.2p1 |
| 2 | `dmz-mail01/` | `dmzmail01` | DMZ | Ubuntu 24.04 LTS | Postfix 3.7.11, Dovecot 2.3.19.1, Roundcube 1.4.14, Apache 2.4.59 |
| 3 | `dmz-ftp01/` | `dmzftp01` | DMZ | Ubuntu 24.04 LTS | ProFTPD 1.3.5 + `mod_copy`, vsftpd 3.0.5, Apache 2.4.59 |
| 4 | `int-dc01/` | `intdc01` | Internal | Windows Server 2019 | AD DS / Kerberos, SMB 2/3 and SMBv1, RDP 10.0 |
| 5 | `int-erp01/` | `interp01` | Internal | Ubuntu 24.04 LTS | Flask ERP 3.0.x (Python 3.12.3), PostgreSQL 16.2, MS SQL Server 2017/2019 (sim) |
| 6 | `int-dev01/` | `intdev01` | Internal | Ubuntu 24.04 LTS | GitLab CE 14.0.12-ce.0, Jenkins 2.387.1, Docker Engine 24.0.7 or 26.1.3 (API 1.43 / 1.45) |
| 7 | `int-files01/` | `intfiles01` | Internal | Debian 13 | Samba 4.17.12 or 4.18.0, nfs-kernel-server 2.6.2 |
| 8 | `int-ws01/` | `int-win10-01` | Internal | Windows 10 | SMBv1, Print Spooler 10.0, RDP 10.0 |
| 9 | `rz-db01/` | `rzdb01` (3 instances) | Restricted | Ubuntu 24.04 LTS | MySQL Community 8.0.36, PostgreSQL 16.2, Redis 7.0.15 or 7.2.4 |
| 10 | `rz-vpn01/` | `rzvpn01` | Restricted | Ubuntu 24.04 LTS | Flask VPN admin 3.0.x (Python 3.12.3), OpenVPN 2.6.9 |
| — | *(not in this repo)* | `VM-Attacker` | Attacker | Kali Linux (latest) | MITRE Caldera (latest) |
| — | `rz-monitor01/` | extra lab host, not in the Phase 1 VM list | Restricted | Debian 13 | optional |
| — | `int-backup01/` | extra lab host, not in the Phase 1 VM list | Internal | Debian 13 | optional |

Zone counts in the spec: DMZ 4 (3 servers + Scan-Agent), Internal 6 (5 servers + Scan-Agent), Restricted 5 (`rzdb01` ×3, `rzvpn01`, Scan-Agent), Management = ASPER workstations, Attacker 1. Linux log agents are Filebeat, Auditbeat, and Packetbeat; Windows uses Winlogbeat. ASPER deploys those agents. Phase 2 target is at least 100 VMs.

---

## ⚡ General Deployment Workflow (Linux VMs)

1. Boot the fresh VM (set static IP as per `BUILD_GUIDE.md`).
2. Clone your repository or copy the corresponding machine subfolder to `/opt/<machine-name>` on the VM.
3. **Update IP addresses** in `docker-compose.yml` and `deploy.sh` to match your lab network.
4. Run the one-command deployment script:
   ```bash
   chmod +x deploy.sh
   sudo ./deploy.sh
   ```
5. The script automatically detects if `offline_installer/` exists to perform a **100% offline Docker & Compose installation** without requiring internet access.
6. **SSH access** is on port **2222** (not 22) to avoid conflicts with the Debian host's own SSH service.

---

## 📦 Offline / Air-Gapped Installation Guide

If your lab machines are on an isolated, air-gapped network with no internet access:

1. **Pre-download Docker binaries & images** on an internet-connected machine:
   ```bash
   chmod +x offline_installer/download_offline_assets.sh
   ./offline_installer/download_offline_assets.sh
   ```
   *(Or on Windows: `.\offline_installer\download_offline_assets.ps1`)*

2. **Copy the entire `VulnMach` workspace** (including `offline_installer/`) to the offline VM via USB or SCP.

3. **Deploy as normal**:
   ```bash
   sudo ./deploy.sh
   ```
   `deploy.sh` will install Docker Engine, Docker Compose, and load all container images 100% offline!

