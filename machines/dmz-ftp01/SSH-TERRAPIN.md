# SSH Terrapin check on 192.168.20.32

Host: `dmzftp01` (`192.168.20.32`). This note covers the OpenVAS Terrapin SSH result only. ProFTPD was not part of this change.

## What OpenVAS was matching

The check does not stop at the version banner. It reports a match when the SSH server still offers either of these:

- cipher `chacha20-poly1305@openssh.com`
- a CBC cipher together with an Encrypt-then-MAC (`*-etm@openssh.com`)

The finding’s own fix line is OpenSSH **9.6** or later. Its quality of detection is low because a current OpenSSH build can still advertise those algorithms.

## What was already installed

No OpenSSH package upgrade was required. The host was already on a newer build:

```text
OpenSSH_10.0p2 Debian-7+deb13u4
```

That is past 9.6, so the strict key-exchange fix is already in this package. OpenVAS still matched because the old algorithm list was enabled.

Before the change, `sshd` offered:

- Ciphers: `chacha20-poly1305@openssh.com`, `aes128-gcm@openssh.com`, `aes256-gcm@openssh.com`, `aes128-ctr`, `aes192-ctr`, `aes256-ctr`
- MACs: several `*-etm@openssh.com` algorithms, plus `hmac-sha2-256` and `hmac-sha2-512`

## What was changed

File added on the host:

`/etc/ssh/sshd_config.d/99-terrapin.conf`

```text
Ciphers aes128-gcm@openssh.com,aes256-gcm@openssh.com,aes128-ctr,aes192-ctr,aes256-ctr
MACs hmac-sha2-256,hmac-sha2-512
```

`sshd -t` was run, then `systemctl restart ssh`. A new login to `dmzftp01` succeeded after the restart.

## What a scanner sees now

Banner, unchanged:

```text
remote software version OpenSSH_10.0p2 Debian-7+deb13u4
```

Server key-exchange proposal after the restart:

- Ciphers: `aes128-gcm@openssh.com`, `aes256-gcm@openssh.com`, `aes128-ctr`, `aes192-ctr`, `aes256-ctr`
- MACs: `hmac-sha2-256`, `hmac-sha2-512`

`chacha20-poly1305@openssh.com` and the `*-etm` MACs are not in that proposal, so this Terrapin check no longer matches. Rescan port **22** to clear the previous result.
