# dmz-ftp01 offline pack

This folder holds **air-gapped install assets** for host (docker-less) deploy.

## What must be present before offline deploy

| Path | Required | How it gets there |
|------|----------|-------------------|
| `proftpd-1.3.5-linux-amd64.tar.gz` | **Yes** | `sudo ./prepare-offline.sh` (packs `/opt/proftpd-1.3.5`) |
| `debs/*.deb` | Strongly recommended | Same prepare script (`apt` download) |
| `READY.txt` / `SHA256SUMS.txt` | Optional | Written by prepare |
| `DEB-MANIFEST.txt` | Optional | Written by prepare |

Lab configs are **not** only here — they live in `../files/` and are always copied by `deploy-offline.sh`.

## Prepare (online machine)

```bash
cd machines/dmz-ftp01
sudo ./prepare-offline.sh
```

## Transfer to air-gapped VM

Copy the **entire** directory:

```text
machines/dmz-ftp01/
```

USB / SCP / shared folder — include `offline/`, `files/`, `setup/`, and `deploy-offline.sh`.

Minimum set if you must trim:

```text
dmz-ftp01/
├── deploy-offline.sh
├── files/                  # configs + units + vsftpd lab script
├── setup/
│   ├── setup_breadcrumbs.sh
│   └── verify_lab.sh
└── offline/
    ├── proftpd-1.3.5-linux-amd64.tar.gz
    └── debs/*.deb
```

## Install (offline machine — no internet)

```bash
cd machines/dmz-ftp01
sudo ./deploy-offline.sh
sudo ./setup/verify_lab.sh
```
