# dmzweb01 — 192.168.20.29

Host: `dmzweb01`, Debian 13. Login is the existing `debian` account. `192.168.20.32` was not changed.

App tree on the host: `/home/debian/Webserver/`. These scripts are unchanged and still run at image build:

| File | Role |
|------|------|
| `deploy.sh` | Build and start the stack |
| `Dockerfile` | Image: Debian bookworm, Python 3.11.2, Flask, cron, plus unused openssh/vsftpd packages |
| `setup/setup_privesc.sh` | SUID, cron, sudo, shadow |
| `setup/setup_services.sh` | Writes container SSH/FTP configs (those daemons are not started) |
| `setup/setup_breadcrumbs.sh` | Notes, key, database config, flags |
| `docker-compose.yml` | Publishes **8080** only |
| `entrypoint.sh` | Starts **cron** and **Flask** only |

Commands used on this host:

```bash
cd /home/debian/Webserver
docker compose up -d --force-recreate --build
sshd -t && systemctl restart ssh
systemctl restart vsftpd
```

Check listeners:

```bash
ss -lntup
docker ps
docker exec vulncorp-server ss -lnt
```

## Host vs Docker

| Service | Where | Exposed on the LAN | Version seen |
|---------|--------|--------------------|--------------|
| OpenSSH | **Host** `ssh` | **22** | `openssh-server 1:10.0p1-7+deb13u4` |
| vsftpd | **Host** | **21** (passive **40000–40010** during a transfer) | **3.0.5-0.2**, banner `(vsftpd 3.0.5)` |
| Flask | **Docker** `vulncorp-server` | **8080** → container **80** | Flask **3.1.3**, Python **3.11.2** |
| cron | **Docker** | not a port | runs `/opt/scripts/cleanup.sh` |
| Container OpenSSH | installed in the image | **not listening** | config only (`setup_services.sh`) |
| Container vsftpd | installed in the image | **not listening** | config only (`setup_services.sh`) |
| CUPS | Host | **127.0.0.1:631** only | local print service |
| Avahi | Host | UDP **5353** | mDNS |

Nothing is listening on **2121** or **2222**.

## Exposed and scanner-visible

| Item | Port | What a scanner can match | ID |
|------|------|--------------------------|----|
| Anonymous FTP, anonymous write (`STOR` into `/var/ftp/pub`) | 21 | Nessus 10079; OpenVAS anonymous FTP / anonymous write | CWE-276 |
| FTP banner `(vsftpd 3.0.5)` | 21 | Version banner matches the installed package | CWE-200 |
| Flask login SQL string formatting | 8080 `/login` | Web SQLi | CWE-89 |
| `/nettools` passes input to a shell command | 8080 | Command injection | CWE-78 |
| `/upload` and `/cgi/<script>` | 8080 | Unrestricted upload / script run | CWE-434 |
| `/viewer?file=` reads a chosen path | 8080 | Path traversal | CWE-22 |
| `/notes` renders stored content as HTML | 8080 | Stored XSS | CWE-79 |
| `/robots.txt`, `/server-status` | 8080 | Info disclosure | CWE-200 |
| Host SSH password login | 22 | Password authentication enabled | CWE-521 |
| Terrapin algorithms | 22 | **Not offered** (`chacha20-poly1305` and `*-etm` removed) | false positive cleared |

Host SSH settings now: `PermitRootLogin no`, `PasswordAuthentication yes`, ciphers AES-GCM/CTR only, MACs `hmac-sha2-256` and `hmac-sha2-512`. Drop-in: `/etc/ssh/sshd_config.d/99-terrapin.conf`. FTP config: `/etc/vsftpd.conf`. Anonymous root: `/var/ftp`.

## Inside the container only (not a network port)

These come from the setup scripts and matter after a shell on the web app. They are not separate exposed services.

| Weakness | Location | ID |
|----------|----------|----|
| SUID backup helper | `/usr/local/bin/vuln-backup` | CWE-426 |
| World-writable root cron script | `/opt/scripts/cleanup.sh`, `/etc/cron.d/vulncorp-cleanup` | CWE-732 |
| Passwordless sudo | `webuser` → `find`, `backup` → `vim` | CWE-269 |
| World-readable shadow | `/etc/shadow` mode `644` | CIS |
| Plaintext DB config | `/opt/vulncorp/config/database.yml` | CWE-312 |
| Notes and key material | `/root/notes.txt`, `/root/.ssh/` | CWE-312 |

OpenVAS on this host: include **21**, **22**, and **8080**. Anonymous login and `STOR` into `/var/ftp/pub` are what the anonymous-FTP checks use. The banner is the real package string `(vsftpd 3.0.5)`, so a scan does not treat this service as vsftpd 2.x.

`machines/dmz-ftp01` is a different host (`192.168.20.32`). Its OpenVAS CVEs are CVE-2011-2523 (port 21, then 6200) and CVE-2015-3306 (port 2121). Those services are not installed on `dmzweb01`. Rescan **22** for Terrapin and **21** / **8080** for the table above.
