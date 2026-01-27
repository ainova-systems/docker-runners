# AI Automation Runner
# Extends base-runner with Claude CLI & Cursor CLI
#
# Build: docker build -t ai-runner:latest .
# Run:   docker run -d \
#          -e GITHUB_REPOSITORY_URL=https://github.com/org/repo \
#          -e GITHUB_RUNNER_TOKEN=<token> \
#          -e ANTHROPIC_API_KEY=<key> \
#          ai-runner:latest

ARG BASE_IMAGE=ghcr.io/ainova-systems/docker-runners/base-runner:latest
FROM ${BASE_IMAGE}

# Labels
LABEL org.opencontainers.image.source="https://github.com/ainova-systems/docker-runners"
LABEL org.opencontainers.image.description="GitHub Actions self-hosted runner with Claude CLI & Cursor CLI"

# Switch to root for installations
USER root

# Install Claude CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Add runner to docker group (for optional Docker access)
RUN usermod -aG docker runner || true

# Copy entrypoint script (overrides base)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to runner user
USER runner
WORKDIR /home/runner

# Install Cursor CLI for runner user
# Install path: ~/.local/bin/cursor-agent (per official docs)
RUN NO_COLOR=1 bash -c "$(curl -fsSL https://cursor.com/install)" \
    && test -x "$HOME/.local/bin/cursor-agent" \
    && echo "Cursor CLI installed: $($HOME/.local/bin/cursor-agent --version)"

# Add Cursor CLI to PATH
ENV PATH="/home/runner/.local/bin:${PATH}"

WORKDIR /home/runner/actions-runner

# Default labels for AI automation
ENV RUNNER_LABELS=self-hosted,claude-cli,cursor-agent

ENTRYPOINT ["/entrypoint.sh"]
