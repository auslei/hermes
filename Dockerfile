FROM nousresearch/hermes-agent:latest

# Accept UID/GID dynamically without hardcoded defaults
ARG UID
ARG GID

USER root

# 1. Install Docker CLI (Linux native) to allow container to execute docker commands via the socket
RUN apt-get update && apt-get install -y ca-certificates curl gnupg sudo && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install -y docker-ce-cli


# 2. Existing User Setup Logic using dynamic variables
RUN groupadd -g 999 docker_host && usermod -aG docker_host hermes || true

RUN if ! getent group ${GID} >/dev/null; then groupadd -g ${GID} hermes_host; fi && \
    if ! getent passwd ${UID} >/dev/null; then useradd -m -u ${UID} -g ${GID} -s /bin/bash hermes_host; fi

# 3. Install Node 22 and Chrome dependencies
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs \
    libnss3 libatk-bridge2.0-0 libxcomposite1 libxdamage1 \
    libxrandr2 libgbm1 libasound2 libpangocairo-1.0-0 \
    libpango-1.0-0 libcups2 libdrm2 libxkbcommon0 && \
    rm -rf /var/lib/apt/lists/*

# 4. Pre-install WhatsApp bridge dependencies
WORKDIR /opt/hermes/scripts/whatsapp-bridge
RUN npm install

# 5. Give ownership of the app directory to the dynamically assigned user
RUN chown -R ${UID}:${GID} /opt/hermes

# 6. Allow passwordless sudo (MUST BE DONE AS ROOT)
RUN echo "ALL ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

WORKDIR /opt/hermes
USER ${UID}