#!/bin/bash
# ================================================================
# VulnCorp — Machine 9: int-dev01 One-Command Deploy Script
# ================================================================
set -e
echo "============================================="
echo "  Deploying VulnCorp DevOps (int-dev01)      "
echo "============================================="

# Detect the VM's outbound IP to show correct access URLs
VM_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "YOUR_VM_IP")

# Ensure curl and nc are available (some fresh Debian VMs lack them)
if ! command -v curl &> /dev/null || ! command -v nc &> /dev/null; then
    echo "[*] Installing curl and netcat..."
    apt-get update -qq && apt-get install -y -qq curl netcat-openbsd
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

# Clean up any previous deployment
echo "[*] Stopping any previous containers..."
docker compose down --remove-orphans 2>/dev/null || true

echo "[*] Building and starting all services..."
echo "    (3 containers: vulncorp-dev01, vulncorp-gitlab, vulncorp-jenkins)"
docker compose up -d --build

echo ""
echo "[*] Waiting for all services to come up..."
echo "    (GitLab takes 3-5 minutes on first boot — please be patient)"
echo ""

# Disable exit-on-error for health checks (we want to report all statuses)
set +e

# ── Check SSH ─────────────────────────────────────────────────────────────────
printf "    %-14s [:%-4s] ... " "SSH" "2222"
for i in $(seq 1 30); do
    if nc -z 127.0.0.1 2222 2>/dev/null; then
        echo "✅  UP"
        break
    fi
    [ $i -eq 30 ] && echo "❌  NOT responding after 30s"
    sleep 1
done

# ── Check Docker API ──────────────────────────────────────────────────────────
printf "    %-14s [:%-4s] ... " "Docker API" "2375"
for i in $(seq 1 30); do
    if curl -sf "http://127.0.0.1:2375/version" > /dev/null 2>&1; then
        echo "✅  UP"
        break
    fi
    [ $i -eq 30 ] && echo "❌  NOT responding after 30s"
    sleep 1
done

# ── Check Jenkins ─────────────────────────────────────────────────────────────
printf "    %-14s [:%-4s] ... " "Jenkins" "8080"
for i in $(seq 1 120); do
    if curl -sf "http://127.0.0.1:8080" > /dev/null 2>&1; then
        echo "✅  UP"
        break
    fi
    [ $i -eq 120 ] && echo "❌  NOT responding after 120s"
    sleep 1
done

# ── Check GitLab ──────────────────────────────────────────────────────────────
printf "    %-14s [:%-4s] ... " "GitLab" "80"
for i in $(seq 1 300); do
    if curl -sf "http://127.0.0.1:80" > /dev/null 2>&1; then
        echo "✅  UP"
        break
    fi
    [ $i -eq 300 ] && echo "❌  NOT responding after 5 mins (may still be starting)"
    sleep 1
done

set -e

echo ""
echo "============================================="
echo "  int-dev01 DEPLOYED!                        "
echo "============================================="
echo "  GitLab (root/gitlab_root_pass): http://${VM_IP}:80"
echo "  Jenkins (No Auth):              http://${VM_IP}:8080"
echo "  Docker API (No TLS):            curl http://${VM_IP}:2375/version"
echo "  SSH (developer/dev123):         ssh developer@${VM_IP} -p 2222"
echo "============================================="
echo ""
echo "  📋 Debug (if anything failed):"
echo "     docker logs vulncorp-dev01"
echo "     docker logs vulncorp-gitlab"
echo "     docker logs vulncorp-jenkins"
echo "============================================="


