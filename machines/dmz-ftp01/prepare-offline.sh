#!/bin/bash
# ================================================================
# Run ONCE on a machine WITH internet (Debian/Ubuntu amd64),
# preferably the same OS as the lab VM (Debian 13).
#
# Fills machines/dmz-ftp01/offline/ so deploy-offline.sh can
# install with NO network.
#
# Usage:
#   cd machines/dmz-ftp01
#   sudo ./prepare-offline.sh
# ================================================================
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo ./prepare-offline.sh" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
OFF="$ROOT_DIR/offline"
DEB="$OFF/debs"
mkdir -p "$DEB" "$OFF"

export DEBIAN_FRONTEND=noninteractive

echo "[+] Building/ensuring ProFTPD 1.3.5 + mod_copy..."
bash "$ROOT_DIR/setup/install_proftpd_135.sh"

echo "[+] Packing /opt/proftpd-1.3.5 into offline tarball..."
tar -C /opt -czf "$OFF/proftpd-1.3.5-linux-amd64.tar.gz" proftpd-1.3.5
ls -lh "$OFF/proftpd-1.3.5-linux-amd64.tar.gz"

echo "[+] Downloading .deb packages (and dependencies) into offline/debs/..."
PKGS=(
  apache2
  apache2-bin
  apache2-data
  apache2-utils
  python3
  python3-minimal
  libcap2-bin
  curl
  wget
  net-tools
  ftp
  ca-certificates
)

apt-get update -qq
# Download without installing; pull recommends off to keep set smaller
apt-get install -y --download-only --reinstall -o Dir::Cache::archives="$DEB" \
  --no-install-recommends "${PKGS[@]}" || true

# Also copy anything already cached that matches our names
shopt -s nullglob
cp -n /var/cache/apt/archives/*.deb "$DEB/" 2>/dev/null || true

# Resolve recursive deps into the same folder (best-effort)
for p in "${PKGS[@]}"; do
  apt-get download -o Dir::Cache::archives="$DEB" -y "$p" 2>/dev/null || true
done

# Force a fuller dependency download via apt-get install --download-only
cd "$DEB"
apt-get install -y --download-only --reinstall --no-install-recommends \
  apache2 python3 libcap2-bin net-tools ftp ca-certificates 2>/dev/null || true
# Move freshly downloaded debs from default cache if needed
cp -n /var/cache/apt/archives/*.deb "$DEB/" 2>/dev/null || true

# Manifest
(
  cd "$OFF"
  find debs -name '*.deb' | sort > DEB-MANIFEST.txt
  sha256sum proftpd-1.3.5-linux-amd64.tar.gz > SHA256SUMS.txt
  sha256sum debs/*.deb >> SHA256SUMS.txt 2>/dev/null || true
)

cat > "$OFF/READY.txt" << EOF
offline pack prepared: $(date -u +%Y-%m-%dT%H:%M:%SZ)
host: $(hostname)
os: $(. /etc/os-release; echo "$PRETTY_NAME")
arch: $(uname -m)
proftpd: $(/opt/proftpd-1.3.5/sbin/proftpd -v 2>/dev/null || echo packed)
deb_count: $(find "$DEB" -name '*.deb' | wc -l)
EOF

echo
echo "[+] Offline pack ready at: $OFF"
echo "    Transfer the whole machines/dmz-ftp01/ folder to the air-gapped VM."
echo "    On the VM run:  sudo ./deploy-offline.sh"
cat "$OFF/READY.txt"
