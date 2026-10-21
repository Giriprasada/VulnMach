# 🏢 VulnCorp Enterprise Lab — Machine Deployment Packages

> 📝 **IP Note:** All IP addresses listed below are defaults/placeholders. Change them to match your actual lab network layout in each machine's `docker-compose.yml` and `deploy.sh` (or `deploy_dc.ps1` / `deploy_ws.ps1` for Windows) before deploying.

Every machine in the VulnCorp Enterprise testbed is organized as a self-contained, deployable package with its own `Dockerfile`, `docker-compose.yml`, and `deploy.sh` (or `deploy_dc.ps1` / `deploy_ws.ps1` for Windows).

---

## 🗺️ Master Machine Index

| # | Folder | Target VM Hostname | Zone | OS | SSH Port | Quick Deploy Command |
|---|--------|--------------------|------|----|----------|----------------------|
| 1 | `../` *(root)* | `vulncorp-web01` | DMZ (`10.10.10.10`) | Debian 13 | 2222 | `sudo ./deploy.sh` |
| 2 | `dmz-mail01/` | `vulncorp-mail01` | DMZ (`10.10.10.20`) | Debian 13 | 2222 | `sudo ./deploy.sh` |
| 3 | `dmz-ftp01/` | `vulncorp-ftp01` | DMZ (`10.10.10.30`) | Debian 13 | 22 (host) | `sudo ./deploy.sh` **(host / docker-less)** |
| 4 | `rz-db01/` | `vulncorp-db01` | Restricted (`172.16.0.10`) | Ubuntu 24 | 2222 | `sudo ./deploy.sh` |
| 5 | `rz-vpn01/` | `vulncorp-vpn01` | Restricted (`172.16.0.20`) | Ubuntu 24 | 2222 | `sudo ./deploy.sh` |
| 6 | `rz-monitor01/` | `vulncorp-monitor01` | Restricted (`172.16.0.30`) | Debian 13 | 2222 | `sudo ./deploy.sh` |
| 7 | `int-dc01/` | `VULNCORP-DC01` | Internal (`192.168.1.10`) | Win Server 2019 | 3389 (RDP) | `.\deploy_dc.ps1` *(PowerShell Admin)* |
| 8 | `int-erp01/` | `vulncorp-erp01` | Internal (`192.168.1.20`) | Ubuntu 24 | 2222 | `sudo ./deploy.sh` |
| 9 | `int-dev01/` | `vulncorp-dev01` | Internal (`192.168.1.30`) | Ubuntu 24 | 2222 | `sudo ./deploy.sh` |
| 10 | `int-files01/` | `VULNCORP-FILES01` | Internal (`192.168.1.40`) | Debian 13 | 2222 | `sudo ./deploy.sh` |
| 11 | `int-backup01/` | `vulncorp-backup01` | Internal (`192.168.1.50`) | Debian 13 | 2222 | `sudo ./deploy.sh` |
| 12 | `int-ws01/` | `VULNCORP-WS01` | Internal (`192.168.1.60`) | Win 10 / Debian 13 | 2222 (Docker) / 3389 (RDP) | `sudo ./deploy.sh` *(Docker)* or `.\deploy_ws.ps1` *(PowerShell Admin)* |

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

