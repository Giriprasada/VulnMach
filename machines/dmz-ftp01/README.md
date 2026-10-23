# VulnCorp — Machine 3: dmz-ftp01 (FTP Server)

> **FOR EDUCATIONAL / LAB USE ONLY — NEVER EXPOSE TO THE INTERNET**
>
> **Deployment model: HOST (docker-less).** Services run under **systemd**.
> Prefer **offline** deploy when the VM has no internet.

Default lab IP: `10.10.10.30` (example live host: `192.168.20.32`)

---

## What to copy to the lab machine

Send the **entire** folder:

```text
machines/dmz-ftp01/
```

USB / SCP / shared folder. After `prepare-offline.sh`, that folder includes the offline assets.

### Minimum set for air-gapped install

```text
dmz-ftp01/
├── README.md
├── deploy.sh                 # auto-uses offline if pack present
├── deploy-offline.sh         # force offline install
├── prepare-offline.sh        # only needed on the ONLINE builder
├── files/                    # REQUIRED configs + units + vsftpd lab script
│   ├── vsftpd-234-lab.py
│   ├── vsftpd-234-lab.service
│   ├── proftpd.conf
│   ├── proftpd-lab.service
│   └── apache-proftpd-lab.conf
├── setup/
│   ├── setup_breadcrumbs.sh  # REQUIRED
│   ├── verify_lab.sh
│   ├── install_proftpd_135.sh   # online build only
│   └── setup_host_services.sh   # online install only
└── offline/                  # REQUIRED for air-gap
    ├── README.md
    ├── proftpd-1.3.5-linux-amd64.tar.gz   # REQUIRED
    └── debs/                 # .deb packages (apache2, python3, …)
        └── *.deb
```

You do **not** need to copy `Dockerfile` / `docker-compose.yml` for host offline deploy.

---

## Offline install (recommended for lab VMs)

### 1) On a machine WITH internet (same OS/arch as lab — Debian amd64)

```bash
cd machines/dmz-ftp01
chmod +x *.sh setup/*.sh
sudo ./prepare-offline.sh
```

This fills `offline/proftpd-1.3.5-linux-amd64.tar.gz` and `offline/debs/*.deb`.

### 2) Transfer

Copy whole `machines/dmz-ftp01/` to the air-gapped VM.

### 3) On the air-gapped VM (no internet)

```bash
cd machines/dmz-ftp01
sudo ./deploy-offline.sh
# or: sudo ./deploy.sh   # auto-detects offline pack
sudo ./setup/verify_lab.sh
```

---

## Online install (needs internet)

Only if `offline/proftpd-1.3.5-linux-amd64.tar.gz` is missing:

```bash
cd machines/dmz-ftp01
sudo ./deploy.sh
```

Uses `apt` + downloads ProFTPD 1.3.5 source to build `/opt/proftpd-1.3.5`.

---

## Services on the host after deploy

| Service | systemd unit | Port | Vulnerability |
|---------|--------------|------|---------------|
| vsftpd 2.3.4 lab | `vsftpd-234-lab.service` | **21** (+ **6200** after `USER …:)`) | **CVE-2011-2523** |
| ProFTPD 1.3.5 + `mod_copy` | `proftpd-lab.service` | **2121** | **CVE-2015-3306** |
| Apache | `apache2` | **80** | DocumentRoot `/var/www/html` |
| OpenSSH | `ssh` | **22** | Lab access |

### Host paths

| Path | Role |
|------|------|
| `/usr/local/sbin/vsftpd-234-lab.py` | Port 21 lab stub |
| `/opt/proftpd-1.3.5/` | ProFTPD binary + `etc/proftpd.conf` |
| `/var/www/html/` | Apache document root |
| `/var/ftp/pub/` | Breadcrumb files / flags |

---

## OpenVAS

Include ports **21, 80, 2121, 6200**.

| CVE | Port |
|-----|------|
| CVE-2011-2523 | 21 → trigger → 6200 |
| CVE-2015-3306 | 2121 (`SITE CPFR`/`CPTO`) |

---

## Flags

- `/var/ftp/pub/flag1.txt` → `VULN{anon_ftp_wr1t3}`
- `/var/ftp/pub/keys/flag.txt` → `VULN{ssh_k3y_l3ak3d}`
- `/root/root.txt` → `VULN{ftp_s3rv3r_r00t3d_m4ch1n3_3}`

## Credentials & SSH Access

- **Root SSH:** `root` / `toor` (PermitRootLogin enabled, password authentication allowed)
- **Lab FTP User:** `ftpuser` / `ftp123`
- **SSH Banner:** Pre-auth banner active at `/etc/ssh/banner.txt` (reveals OS, hostname, contact)
- **SSH Ciphers:** Restricted via `/etc/ssh/sshd_config.d/99-terrapin.conf` to clear Terrapin false positives in OpenVAS

---

## Legacy Docker

`Dockerfile`, `docker-compose.yml`, `entrypoint.sh` are **legacy**. Do not run them alongside host systemd (port conflicts).
