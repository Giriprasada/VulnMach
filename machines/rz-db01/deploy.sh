#!/bin/bash
# ================================================================
# VulnCorp — Machine 4: rz-db01 One-Command Deploy Script
# ================================================================
set -e
echo "============================================="
echo "  Deploying VulnCorp DB Server (rz-db01)     "
echo "============================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for offline Docker installer package
OFFLINE_SCRIPT=""
for candidate in "$SCRIPT_DIR/../../offline_installer/install_offline_docker.sh" \
                 "$SCRIPT_DIR/../offline_installer/install_offline_docker.sh" \
                 "$SCRIPT_DIR/offline_installer/install_offline_docker.sh" \
                 "/opt/offline_installer/install_offline_docker.sh"; do
    if [ -f "$candidate" ]; then
        OFFLINE_SCRIPT="$candidate"
        break
    fi
done

if [ -n "$OFFLINE_SCRIPT" ]; then
    echo "[*] Found offline Docker installer package at: $OFFLINE_SCRIPT"
    bash "$OFFLINE_SCRIPT" || true
fi

if ! command -v docker &> /dev/null; then
    echo "[*] Installing Docker (online fallback)..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker 2>/dev/null || true
fi

if ! docker compose version &> /dev/null && ! command -v docker-compose &> /dev/null; then
    echo "[*] Installing Docker Compose plugin..."
    apt-get update -qq && apt-get install -y docker-compose-v2 || true
fi

echo "[*] Building and starting rz-db01 container..."
docker compose up -d --build

echo ""
echo "============================================="
echo "  rz-db01 DEPLOYED SUCCESSFULLY!             "
echo "============================================="
echo "  MySQL (root/toor):       Port 3306"
echo "  PostgreSQL (COPY Prog):  Port 5432"
echo "  Redis (No Auth):         Port 6379"
echo "  SSH:                     Port 22"
echo "============================================="
