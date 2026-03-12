#!/bin/bash
set -e

# E2E Test Runner Entrypoint
# This script configures and starts the GitHub Actions runner

echo "=========================================="
echo "E2E Test Runner v1.0"
echo "=========================================="

# Validate required environment variables
# GITHUB_REPOSITORY_URL and GITHUB_RUNNER_TOKEN are only required for initial setup
# After first run, credentials are persisted in volumes
if [ ! -f ".credentials" ]; then
    if [ -z "$GITHUB_REPOSITORY_URL" ]; then
        echo "ERROR: GITHUB_REPOSITORY_URL is required for initial configuration"
        echo "Example: https://github.com/your-org/your-repo"
        exit 1
    fi
    if [ -z "$GITHUB_RUNNER_TOKEN" ]; then
        echo "ERROR: GITHUB_RUNNER_TOKEN is required for initial configuration"
        echo "Get it from: Repository -> Settings -> Actions -> Runners -> New self-hosted runner"
        exit 1
    fi
fi

# Set runner name
RUNNER_NAME=${RUNNER_NAME:-"test-runner-$(hostname)"}

# Set runner labels
LABELS=${RUNNER_LABELS:-"self-hosted,e2e-tests,playwright"}

echo ""
echo "Configuration:"
[ -n "$GITHUB_REPOSITORY_URL" ] && echo "  Repository URL: $GITHUB_REPOSITORY_URL"
echo "  Runner Name:    $RUNNER_NAME"
echo "  Labels:         $LABELS"
[ -f ".credentials" ] && echo "  Status:         Configured (using persisted credentials)"
echo ""

# Check if runner is already configured with valid credentials
if [ -f ".runner" ] && [ -f ".credentials" ]; then
    echo "Runner already configured, reusing existing configuration..."
    echo "To force reconfiguration, remove the runner-config volumes"
else
    # Validate token is provided for new configuration
    if [ -z "$GITHUB_RUNNER_TOKEN" ]; then
        echo "ERROR: GITHUB_RUNNER_TOKEN is required for initial configuration"
        echo "Get it from: Repository -> Settings -> Actions -> Runners -> New self-hosted runner"
        exit 1
    fi

    # Remove partial configuration if exists
    if [ -f ".runner" ]; then
        echo "Removing incomplete configuration..."
        ./config.sh remove --token "$GITHUB_RUNNER_TOKEN" || true
    fi

    # Configure the runner
    echo "Configuring runner..."
    ./config.sh \
        --url "$GITHUB_REPOSITORY_URL" \
        --token "$GITHUB_RUNNER_TOKEN" \
        --name "$RUNNER_NAME" \
        --labels "$LABELS" \
        --unattended \
        --replace

    echo ""
    echo "Runner configured successfully!"
fi
echo ""

echo "Verifying installed tools..."
echo "  Node.js:    $(node --version)"
echo "  npm:        $(npm --version)"
echo "  .NET SDK:   $(dotnet --version)"
echo "  git:        $(git --version | cut -d' ' -f3)"
echo "  gh CLI:     $(gh --version | head -1 | cut -d' ' -f3)"
echo "  ripgrep:    $(rg --version | head -1 | cut -d' ' -f2)"
echo "  jq:         $(jq --version)"
echo "  Playwright: $(npx playwright --version 2>/dev/null || echo 'not found')"
echo ""

# Verify Playwright browsers
echo "Verifying Playwright browsers..."
if [ -d "${PLAYWRIGHT_BROWSERS_PATH:-/opt/playwright-browsers}" ]; then
    echo "  Browsers path: ${PLAYWRIGHT_BROWSERS_PATH:-/opt/playwright-browsers}"
    ls -d ${PLAYWRIGHT_BROWSERS_PATH:-/opt/playwright-browsers}/chromium-* 2>/dev/null && echo "  Chromium: installed" || echo "  Chromium: not found"
else
    echo "  WARNING: Playwright browsers directory not found"
fi
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo "Shutting down runner..."
}

# Trap signals for cleanup
trap cleanup SIGTERM SIGINT

echo "=========================================="
echo "Starting GitHub Actions Runner..."
echo "=========================================="
echo ""

# Run the runner
./run.sh &

# Wait for the runner process
wait $!
