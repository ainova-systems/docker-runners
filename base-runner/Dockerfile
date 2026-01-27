# Base Runner Image
# Common foundation for all GitHub Actions self-hosted runners
#
# Includes: Ubuntu 24.04, Node.js 24, .NET 10, gh CLI, dotnet-ef, GitHub Actions Runner
# Build: docker build -t base-runner:latest .

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Build arguments - update these for new versions
ARG RUNNER_VERSION=2.331.0
ARG NODE_MAJOR=24
ARG DOTNET_VERSION=10.0

# Labels
LABEL org.opencontainers.image.source="https://github.com/ainova-systems/docker-runners"
LABEL org.opencontainers.image.description="Base image for GitHub Actions self-hosted runners"
LABEL org.opencontainers.image.tech-stack="Ubuntu 24.04, Node.js 24, .NET 10, gh CLI"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    jq \
    unzip \
    zip \
    build-essential \
    libssl-dev \
    libffi-dev \
    libicu-dev \
    ca-certificates \
    gnupg \
    ripgrep \
    sudo \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI (gh)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install .NET SDK
RUN wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && ./dotnet-install.sh --channel ${DOTNET_VERSION} --install-dir /usr/share/dotnet \
    && rm dotnet-install.sh \
    && ln -sf /usr/share/dotnet/dotnet /usr/bin/dotnet

# Install .NET EF Core tools
RUN dotnet tool install --global dotnet-ef
ENV PATH="${PATH}:/root/.dotnet/tools"

# Install js-yaml for YAML validation
RUN npm install -g js-yaml

# Create runner user
RUN useradd -m -s /bin/bash runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Setup GitHub Actions runner
WORKDIR /home/runner/actions-runner

RUN curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L \
    https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && rm ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && ./bin/installdependencies.sh \
    && chown -R runner:runner /home/runner

# Copy entrypoint script (child images should override if needed)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Default user and workdir
USER runner
WORKDIR /home/runner/actions-runner

ENV RUNNER_ALLOW_RUNASROOT=false

ENTRYPOINT ["/entrypoint.sh"]
