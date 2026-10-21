# LEGACY image — prefer host deploy: sudo ./deploy.sh
# See README.md (docker-less HOST install).
FROM debian:bookworm-slim

LABEL maintainer="VulnCorp Lab"
LABEL description="LEGACY dmz-ftp01 Docker image — use host systemd deploy instead"
LABEL machine="3"
LABEL status="legacy"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    vsftpd \
    proftpd \
    apache2 \
    openssh-server \
    python3 \
    curl wget net-tools vim sudo ftp \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash ftpuser && echo "ftpuser:ftp123" | chpasswd
RUN mkdir -p /var/ftp/pub/keys && chmod -R 777 /var/ftp

COPY setup/ /opt/setup/
COPY files/ /opt/files/
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /opt/setup/*.sh /entrypoint.sh

# Host scripts expect to run on a real VM; Docker entrypoint is legacy-only.
RUN mkdir -p /var/run/sshd && ssh-keygen -A

EXPOSE 21 22 80 2121 6200 40000-40100

ENTRYPOINT ["/entrypoint.sh"]
