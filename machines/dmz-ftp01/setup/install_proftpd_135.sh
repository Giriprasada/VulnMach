#!/bin/bash
# Build and install ProFTPD 1.3.5 with mod_copy into /opt/proftpd-1.3.5 (host).
# Skip rebuild if a working binary already exists.
set -euo pipefail

PREFIX=/opt/proftpd-1.3.5
SRC_URL="${PROFTPD_SRC_URL:-https://github.com/proftpd/proftpd/archive/refs/tags/v1.3.5.tar.gz}"
WORKDIR="${TMPDIR:-/tmp}/proftpd-1.3.5-build"

if [[ -x "$PREFIX/sbin/proftpd" ]]; then
  ver="$("$PREFIX/sbin/proftpd" -v 2>&1 || true)"
  mods="$("$PREFIX/sbin/proftpd" -l 2>&1 || true)"
  if echo "$ver" | grep -q '1.3.5' && echo "$mods" | grep -qi 'mod_copy'; then
    echo "[+] ProFTPD 1.3.5 with mod_copy already present at $PREFIX — skipping build"
    exit 0
  fi
fi

echo "[+] Installing build dependencies..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq build-essential libssl-dev libpam0g-dev zlib1g-dev \
  libncurses5-dev pkg-config curl ca-certificates

echo "[+] Downloading ProFTPD 1.3.5..."
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
curl -fsSL "$SRC_URL" -o "$WORKDIR/proftpd-1.3.5.tar.gz"
tar -xzf "$WORKDIR/proftpd-1.3.5.tar.gz" -C "$WORKDIR"
SRC_DIR="$(find "$WORKDIR" -maxdepth 1 -type d -name 'proftpd*' | head -1)"

echo "[+] Configuring with mod_copy..."
cd "$SRC_DIR"
./configure \
  --prefix="$PREFIX" \
  --enable-ctrls \
  --with-modules=mod_copy \
  --disable-ident

echo "[+] Compiling and installing to $PREFIX..."
make -j"$(nproc)"
make install
mkdir -p "$PREFIX/etc" "$PREFIX/var"
touch /var/log/proftpd-lab.log

echo "[+] Installed: $($PREFIX/sbin/proftpd -v)"
"$PREFIX/sbin/proftpd" -l | grep -i copy || {
  echo "[-] mod_copy not listed — rebuild failed" >&2
  exit 1
}
echo "[+] ProFTPD 1.3.5 + mod_copy ready"
