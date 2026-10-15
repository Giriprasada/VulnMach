FROM ubuntu:24.04

LABEL maintainer="VulnCorp Lab"
LABEL description="rz-db01 — Intentionally Vulnerable Database Server (MySQL, PostgreSQL, Redis)"
LABEL machine="4"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    mysql-server \
    openssh-server \
    python3 python3-pip \
    curl wget net-tools vim sudo \
    && rm -rf /var/lib/apt/lists/*

COPY setup/ /opt/setup/
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /opt/setup/*.sh /entrypoint.sh
RUN mkdir -p /var/run/sshd && ssh-keygen -A
RUN /opt/setup/setup_db.sh

EXPOSE 22 3306

ENTRYPOINT ["/entrypoint.sh"]
