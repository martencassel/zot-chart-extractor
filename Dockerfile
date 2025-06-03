FROM debian:stable-slim

# Install dependencies: bash, coreutils, tar, wget, curl, yq (Go version)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        coreutils \
        tar \
        findutils \
        wget \
        curl \
        ca-certificates \
        git \
    && rm -rf /var/lib/apt/lists/*

# Install yq (Go version, v4+)
RUN wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq

# Set workdir
WORKDIR /workspace

# Copy your script and any test data into the container
COPY zot-chart-tool.sh ./
# Optionally: COPY test data, e.g. COPY zot/ ./zot/

# Default command: show help
CMD ["bash", "./zot-chart-tool.sh"]
