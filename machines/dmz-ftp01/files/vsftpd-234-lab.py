#!/usr/bin/env python3
"""Host-only VulnCorp lab: vsftpd 2.3.4 banner + CVE-2011-2523 (:) -> TCP/6200).

Educational / lab use only. This is NOT the historical trojaned vsftpd binary.
OpenVAS active check: USER with ":)" then expect a shell answering "id" on port 6200.
"""
import os
import socket
import subprocess
import threading
import time

BANNER = b"220 (vsftpd 2.3.4)\r\n"
ANON_ROOT = "/var/ftp"
LISTEN = "0.0.0.0"
FTP_PORT = 21
BD_PORT = 6200
_started = False
_lock = threading.Lock()


def start_backdoor():
    global _started
    with _lock:
        if _started:
            return
        _started = True

    def serve():
        srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        srv.bind((LISTEN, BD_PORT))
        srv.listen(5)
        while True:
            conn, _ = srv.accept()
            try:
                conn.settimeout(5)
                try:
                    data = conn.recv(1024)
                except Exception:
                    data = b"id\n"
                cmd = data.decode("utf-8", "replace").strip() or "id"
                if cmd.lower().startswith("id"):
                    out = subprocess.check_output(["id"], text=True)
                else:
                    out = subprocess.check_output(
                        cmd, shell=True, text=True, stderr=subprocess.STDOUT, timeout=5
                    )
                conn.sendall((out.rstrip() + "\n").encode())
            except Exception as e:
                try:
                    conn.sendall((str(e) + "\n").encode())
                except Exception:
                    pass
            finally:
                try:
                    conn.close()
                except Exception:
                    pass

    threading.Thread(target=serve, daemon=True).start()
    time.sleep(0.3)


def handle(conn):
    conn.sendall(BANNER)
    user = None
    logged_in = False
    try:
        while True:
            data = conn.recv(4096)
            if not data:
                break
            line = data.decode("utf-8", "replace").strip("\r\n")
            if not line:
                continue
            parts = line.split(" ", 1)
            verb = parts[0].upper()
            arg = parts[1] if len(parts) > 1 else ""
            if verb == "USER":
                user = arg
                if ":)" in user:
                    start_backdoor()
                    conn.sendall(b"331 Please specify the password.\r\n")
                    time.sleep(2)
                    break
                conn.sendall(b"331 Please specify the password.\r\n")
            elif verb == "PASS":
                logged_in = True
                conn.sendall(b"230 Login successful.\r\n")
            elif verb == "SYST":
                conn.sendall(b"215 UNIX Type: L8\r\n")
            elif verb == "FEAT":
                conn.sendall(b"211-Features:\r\n211 End\r\n")
            elif verb == "QUIT":
                conn.sendall(b"221 Goodbye.\r\n")
                break
            elif verb in ("PWD", "XPWD"):
                conn.sendall(b'257 "/"\r\n')
            elif verb == "TYPE":
                conn.sendall(b"200 Switching to Binary mode.\r\n")
            elif verb == "CWD":
                if not logged_in:
                    conn.sendall(b"530 Please login with USER and PASS.\r\n")
                else:
                    conn.sendall(b"250 Directory successfully changed.\r\n")
            else:
                if not logged_in:
                    conn.sendall(b"530 Please login with USER and PASS.\r\n")
                else:
                    conn.sendall(b"502 Command not implemented.\r\n")
    finally:
        try:
            conn.close()
        except Exception:
            pass


def main():
    os.makedirs(ANON_ROOT, exist_ok=True)
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind((LISTEN, FTP_PORT))
    srv.listen(50)
    while True:
        c, _ = srv.accept()
        threading.Thread(target=handle, args=(c,), daemon=True).start()


if __name__ == "__main__":
    main()
