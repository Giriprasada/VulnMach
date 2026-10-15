#!/bin/bash
set -euo pipefail

echo "============================================="
echo "  VulnCorp Database Server (rz-db01)         "
echo "============================================="

if [ -z "${MYSQL_ROOT_PASSWORD:-}" ]; then
  echo "[!] MYSQL_ROOT_PASSWORD is not set. Refusing to start MySQL."
  exit 1
fi

echo "[*] Starting SSH on container port 22..."
service ssh start
if pgrep -x sshd >/dev/null; then
  echo "[+] sshd is running"
else
  echo "[!] sshd failed to start"
  exit 1
fi

echo "[*] Starting MySQL..."
service mysql start

if mysql --protocol=socket -e "SELECT 1" >/dev/null 2>&1; then
  echo "[*] Applying MySQL root password from the environment..."
  mysql --protocol=socket -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}'; CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"
fi

echo "[*] Loading MySQL lab schema if it is not already present..."
schema_count="$(mysql --protocol=tcp -h 127.0.0.1 -uroot -p"${MYSQL_ROOT_PASSWORD}" -Nse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='vulncorp_prod' AND table_name='employees'")"
if [ "${schema_count}" = "0" ]; then
  mysql --protocol=tcp -h 127.0.0.1 -uroot -p"${MYSQL_ROOT_PASSWORD}" < /opt/setup/mysql_init.sql
  echo "[+] MySQL schema loaded"
else
  echo "[+] MySQL schema already present; leaving existing data in place"
fi

echo "[+] MySQL is answering on port 3306"
echo "[*] PostgreSQL and Redis are separate Compose services (postgres:11.2, redis:7.2.5)."
echo "============================================="
exec tail -f /dev/null
