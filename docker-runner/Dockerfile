# Docker Runner
# Extends base-runner with Docker CLI for builds and deployments
#
# Tech Stack: base-runner + Docker CLI + Compose plugin
# Use case: PR previews, integration tests, Docker builds
#
# Build: docker build -t docker-runner:latest .

ARG BASE_IMAGE=ghcr.io/ainova-systems/docker-runners/base-runner:latest
FROM ${BASE_IMAGE}

# Labels
LABEL org.opencontainers.image.source="https://github.com/ainova-systems/docker-runners"
LABEL org.opencontainers.image.description="GitHub Actions self-hosted runner for CI/CD: builds, tests, deployments"
LABEL org.opencontainers.image.tech-stack="base-runner + Docker CLI"

# Switch to root for installations
USER root

# Install Docker CLI + Compose plugin
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Create docker group and add runner user
RUN groupadd -f docker \
    && usermod -aG docker runner

# Copy entrypoint script (overrides base)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to runner user
USER runner
WORKDIR /home/runner/actions-runner

# Default labels for Docker runner
ENV RUNNER_LABELS=self-hosted,docker,dotnet,nodejs

ENTRYPOINT ["/entrypoint.sh"]

