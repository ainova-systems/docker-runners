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

# Create runner user
# Created before the .NET install so that install can hand the directory over in
# the same layer: a later `chown -R` would copy the whole SDK into a new layer.
RUN useradd -m -s /bin/bash runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install .NET SDK
# `runner` owns the install directory because `--channel 10.0` floats: the moment
# Microsoft ships a patch newer than the one baked here, actions/setup-dotnet
# installs it into this directory as the unprivileged runner, and a root-owned
# directory fails the job in `Setup .NET` before anything is compiled.
RUN wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && ./dotnet-install.sh --channel ${DOTNET_VERSION} --install-dir /usr/share/dotnet \
    && rm dotnet-install.sh \
    && ln -sf /usr/share/dotnet/dotnet /usr/bin/dotnet \
    && chown -R runner:runner /usr/share/dotnet

# Install .NET EF Core tools globally (accessible to all users)
ENV DOTNET_TOOLS=/opt/dotnet-tools
RUN mkdir -p ${DOTNET_TOOLS} \
    && dotnet tool install --tool-path ${DOTNET_TOOLS} dotnet-ef
ENV PATH="${PATH}:${DOTNET_TOOLS}:/home/runner/.dotnet/tools"

# Install js-yaml for YAML validation
RUN npm install -g js-yaml

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

# Guard: these are the two directories actions/setup-dotnet writes a newer patch
# into. Asserting them here fails the image build instead of every CI job.
RUN test -w /usr/share/dotnet/host/fxr \
    && test -w /usr/share/dotnet/shared/Microsoft.NETCore.App \
    && dotnet --list-sdks

ENV RUNNER_ALLOW_RUNASROOT=false
ENV PLAYWRIGHT_BROWSERS_PATH=/home/runner/actions-runner/.pw-browsers

ENTRYPOINT ["/entrypoint.sh"]
