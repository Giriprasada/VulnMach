#!/bin/bash
# ================================================================
# VulnCorp — Machine 2: dmz-mail01 One-Command Deploy Script
# ================================================================
set -e
echo "============================================="
echo "  Deploying VulnCorp Mail Server (dmz-mail01)"
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

# Ensure Docker is installed
if ! command -v docker &> /dev/null; then
    echo "[*] Installing Docker (online fallback)..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker 2>/dev/null || true
fi

# Ensure docker compose plugin exists
if ! docker compose version &> /dev/null && ! command -v docker-compose &> /dev/null; then
    echo "[*] Installing Docker Compose plugin..."
    apt-get update -qq && apt-get install -y docker-compose-v2 || true
fi

echo "[*] Building and starting dmz-mail01 container..."
docker compose up -d --build

echo ""
echo "============================================="
echo "  dmz-mail01 DEPLOYED SUCCESSFULLY!          "
echo "============================================="
echo "  SMTP (Open Relay):  Port 25"
echo "  IMAP (Plaintext):   Port 143"
echo "  POP3 (Plaintext):   Port 110"
echo "  SSH:                Port 2222 (admin / Admin@2024!)"
echo "============================================="
