#!/bin/bash
# ================================================================
# VulnCorp — Machine 12: int-ws01 One-Command Deploy Script
# ================================================================
# ⚠️  IP Note: Change MACHINE_IP and DC_IP in docker-compose.yml
#     to match your lab network layout before running.
# ================================================================
set -e
echo "============================================="
echo "  Deploying VulnCorp Workstation (int-ws01)  "
echo "============================================="

# Ensure curl is available (some fresh Debian VMs lack it)
if ! command -v curl &> /dev/null; then
    echo "[*] Installing curl..."
    apt-get update -qq && apt-get install -y -qq curl
fi

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

echo "[*] Building and starting int-ws01 container..."
docker compose up -d --build

echo ""
echo "============================================="
echo "  int-ws01 DEPLOYED SUCCESSFULLY!            "
echo "============================================="
echo "  SMB (SMBv1 / Guest):            Port 445"
echo "  HTTP (Credential Dump):         Port 80"
echo "  SSH (ws_admin/Desktop@2024):    Port 2222"
echo ""
echo "  For real Windows VM: use deploy_ws.ps1     "
echo "============================================="
