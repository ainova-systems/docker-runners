# Build Runner
# Extends base-runner for builds and tests (no Docker dependency)
#
# Use case: CI builds, unit tests, linting, code analysis
# Security: No Docker socket mount required
#
# Build: docker build -t build-runner:latest .

ARG BASE_IMAGE=ghcr.io/ainova-systems/docker-runners/base-runner:latest
FROM ${BASE_IMAGE}

# Labels
LABEL org.opencontainers.image.source="https://github.com/ainova-systems/docker-runners"
LABEL org.opencontainers.image.description="GitHub Actions self-hosted runner for builds and tests"

# No additional installations needed - base-runner has Node.js, .NET, gh CLI

# Default labels for build runner
ENV RUNNER_LABELS=self-hosted,build,dotnet,nodejs

ENTRYPOINT ["/entrypoint.sh"]
