FROM nousresearch/hermes-agent:latest

USER root

RUN groupadd -g 999 docker_host && usermod -aG docker_host hermes

# 1. Install Node 22 and Chrome dependencies
RUN apt-get update && apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs \
    libnss3 libatk-bridge2.0-0 libxcomposite1 libxdamage1 \
    libxrandr2 libgbm1 libasound2 libpangocairo-1.0-0 \
    libpango-1.0-0 libcups2 libdrm2 libxkbcommon0 && \
    rm -rf /var/lib/apt/lists/*

# 2. Pre-install WhatsApp bridge dependencies
WORKDIR /opt/hermes/scripts/whatsapp-bridge
RUN npm install

# 3. FIX: Give the 'hermes' user ownership of the app directory
# This allows 'uv sync' to modify uv.lock
RUN chown -R 1000:1000 /opt/hermes

WORKDIR /opt/hermes
USER 1000