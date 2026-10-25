#!/bin/bash
# ============================================================================
#  VulnCorp — int-dev01 entrypoint
#  This container only runs the Docker API proxy (via socat).
#  SSH is the host sshd only. Jenkins and GitLab are other compose services.
#  Jenkins and GitLab run as separate docker-compose services.
# ============================================================================

echo "============================================="
echo "  VulnCorp DevOps Server (int-dev01)         "
echo "============================================="

# ── Docker API — proxy host socket to TCP 2375 (NO TLS = vulnerability) ───
echo "[*] Exposing Docker API on 0.0.0.0:2375 (NO TLS) via socat..."
if [ -S /var/run/docker.sock ]; then
    socat TCP-LISTEN:2375,fork,reuseaddr,bind=0.0.0.0 UNIX-CONNECT:/var/run/docker.sock > /var/log/socat-docker.log 2>&1 &
    sleep 1
    if nc -z 127.0.0.1 2375 2>/dev/null; then
        echo "[+] Docker API exposed on :2375"
    else
        echo "[!] WARNING: socat started but port 2375 not yet listening"
    fi
else
    echo "[!] WARNING: /var/run/docker.sock not found. Docker API won't be exposed."
fi

echo ""
echo "============================================="
echo "  int-dev01 is ready"
echo "  Docker API: Port 2375 (NO TLS!)"
echo "  ⚠️  FOR EDUCATIONAL USE ONLY"
echo "============================================="

# Keep the container alive
exec tail -f /dev/null


