# E2E Test Runner
# Extends base-runner with Playwright and Chromium for browser-based testing
#
# Build: docker build -t test-runner:latest .
# Run:   docker run -d \
#          -e GITHUB_REPOSITORY_URL=https://github.com/org/repo \
#          -e GITHUB_RUNNER_TOKEN=<token> \
#          test-runner:latest

ARG BASE_IMAGE=ghcr.io/ainova-systems/docker-runners/base-runner:latest
FROM ${BASE_IMAGE}

# Labels
LABEL org.opencontainers.image.source="https://github.com/ainova-systems/docker-runners"
LABEL org.opencontainers.image.description="GitHub Actions self-hosted runner with Playwright for E2E testing"

# Switch to root for installations
USER root

# Install Playwright system dependencies (Chromium requirements)
RUN apt-get update && apt-get install -y \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2t64 \
    libatspi2.0-0 \
    libwayland-client0 \
    && rm -rf /var/lib/apt/lists/*

# Install Playwright CLI globally
RUN npm install -g playwright@latest

# Install Chromium browser via Playwright (only Chromium to keep image smaller)
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/playwright-browsers
RUN npx playwright install chromium \
    && chmod -R 755 ${PLAYWRIGHT_BROWSERS_PATH}

# Copy entrypoint script (overrides base)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to runner user
USER runner
WORKDIR /home/runner/actions-runner

# Default labels for E2E testing
ENV RUNNER_LABELS=self-hosted,e2e-tests,playwright

ENTRYPOINT ["/entrypoint.sh"]
