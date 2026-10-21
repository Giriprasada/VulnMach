# Scanner doc — OpenSSL DoS & OpenSSH regreSSHion only

Non-lab OpenVAS noise on Ubuntu 24.04 hosts. **Do not** treat these as VulnCorp scoring paths.  
Intentional lab vulns (MySQL `root`/`toor`, Postgres 11.2, Redis 7.2.5, etc.) stay in machine READMEs / `VULNERABILITY_AND_CVE_MATRIX.md`.

---

## OpenSSL DoS (name check → needs 3.0.15) = CVE-2024-6119

| | |
|--|--|
| **Lab path?** | **No** — not a VulnCorp attack path |
| **Remove OpenSSL?** | **No** — system library (must stay) |
| **Ubuntu 24.04 fix** | `openssl` / `libssl3t64` **`3.0.13-0ubuntu3.4`** and later (backport) |
| **Banner** | Still shows **`OpenSSL 3.0.13`** → OpenVAS often wants upstream **3.0.15** → **false positive** if package ≥ `…3.4` |
| **rz-db01** | `3.0.13-0ubuntu3.16` → **already OK** |

```bash
dpkg-query -W openssl libssl3t64
sudo apt-get install -y --only-upgrade openssl libssl3t64
```

---

## OpenSSL DoS = CVE-2025-9230

| | |
|--|--|
| **Lab path?** | **No** — same as above, keep package |
| **Ubuntu 24.04 fix** | **`3.0.13-0ubuntu3.6`** and later |
| **rz-db01** | `…3.16` → **already OK** |

---

## OpenSSH regreSSHion = CVE-2024-6387

| | |
|--|--|
| **SSH needed for lab?** | **Yes** (access + intentional weak SSH config where documented) |
| **This CVE a lab path?** | **No** |
| **Ubuntu 24.04 fix** | `openssh-server` **`1:9.6p1-3ubuntu13.3`** and later (backport) |
| **Banner** | Still **`OpenSSH_9.6p1`** → OpenVAS asks for **9.8+** → **false positive** if package ≥ `…13.3` |
| **Do not** | Source-install OpenSSH 9.9 over `/usr` (broke `rz-db01` `ssh.service`) |

Restore / keep apt packages only:

```bash
sudo apt-get update
sudo apt-get install --reinstall -y openssh-client openssh-server openssh-sftp-server
sudo systemctl enable --now ssh
dpkg-query -W openssh-server
sshd -V
```

---

## Apply on which hosts

Same OpenSSL + OpenSSH package checks on all Ubuntu/Debian lab VMs (`rz-db01`, `rz-vpn01`, `rz-monitor01`, `dmz-*`, `int-*` Linux). Windows hosts: N/A.

Terrapin cipher note (separate): `machines/dmz-ftp01/SSH-TERRAPIN.md`.

---

## rz-db01 banner override (so OpenVAS stops matching)

Installed **alongside** apt packages (not replacing distro libs system-wide):

| Component | Path | Banner OpenVAS should see |
|-----------|------|---------------------------|
| OpenSSL | `/usr/local/openssl-3.0.15` | **3.0.15** (≥ 3.0.15 clears CVE-2024-6119 upstream check) |
| OpenSSH | `/usr/local/sbin/sshd` | **OpenSSH_9.9p1, OpenSSL 3.0.15** (≥ 9.8 clears regreSSHion range) |

systemd: `/etc/systemd/system/ssh.service.d/99-local-openssh.conf` runs local `sshd` with `LD_LIBRARY_PATH` to the 3.0.15 libs. Apt `openssh-server` / `openssl` packages remain for rollback.

Lab services unchanged: MySQL `root`/`toor`, Postgres **11.2**, Redis **7.2.5**.

---

## Change log

| Date | Note |
|------|------|
| 2026-10-21 | Documented CVE-2024-6119 / CVE-2025-9230 / CVE-2024-6387. On `rz-db01`, deployed local OpenSSL **3.0.15** + OpenSSH **9.9p1** so SSH banners project fixed versions to OpenVAS. MySQL remains **`root`/`toor`**. |
