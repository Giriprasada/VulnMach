#!/bin/bash
# ================================================================
# VulnCorp — Machine 3: dmz-ftp01 One-Command Deploy Script
# ================================================================
set -e
echo "============================================="
echo "  Deploying VulnCorp FTP Server (dmz-ftp01)  "
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

echo "[*] Building and starting dmz-ftp01 container..."
docker compose up -d --build

echo ""
echo "============================================="
echo "  dmz-ftp01 DEPLOYED SUCCESSFULLY!           "
echo "============================================="
echo "  vsftpd (Anon Write): Port 21"
echo "  ProFTPD (mod_copy):  Port 2121"
echo "  SSH:                 Port 22"
echo "============================================="
