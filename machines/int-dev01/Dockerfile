FROM ubuntu:24.04

LABEL maintainer="VulnCorp Lab"
LABEL description="int-dev01 — SSH server + Docker API exposure (part of VulnCorp DevOps machine)"
LABEL machine="9"

ENV DEBIAN_FRONTEND=noninteractive

# ── Tools: SSH, socat (for Docker API proxy), docker-cli ─────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    socat \
    curl wget \
    gnupg ca-certificates lsb-release \
    net-tools netcat-openbsd iproute2 procps \
    vim sudo git \
    && rm -rf /var/lib/apt/lists/*

# ── Docker CLI (so attacker can use the exposed API from inside the container) ─
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | gpg --dearmor -o /usr/share/keyrings/docker-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-keyring.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
      > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y --no-install-recommends \
      docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# ── SSH: generate host keys ───────────────────────────────────────────────────
RUN mkdir -p /var/run/sshd && ssh-keygen -A

# ── Setup scripts: users, secrets, flags ─────────────────────────────────────
COPY setup/ /opt/setup/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /opt/setup/*.sh /entrypoint.sh

# Bake in users/secrets/flags during image build
RUN /opt/setup/setup_dev.sh

EXPOSE 2375

ENTRYPOINT ["/entrypoint.sh"]

