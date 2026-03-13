#!/bin/bash
set -e

# Runner banner - child images can override RUNNER_BANNER env
echo "=========================================="
echo "${RUNNER_BANNER:-GitHub Actions Self-Hosted Runner}"
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
RUNNER_NAME=${RUNNER_NAME:-"runner-$(hostname)"}

# Set runner labels
LABELS=${RUNNER_LABELS:-"self-hosted"}

echo ""
echo "Configuration:"
[ -n "$GITHUB_REPOSITORY_URL" ] && echo "  Repository:   $GITHUB_REPOSITORY_URL"
echo "  Runner Name:  $RUNNER_NAME"
echo "  Labels:       $LABELS"
[ -f ".credentials" ] && echo "  Status:       Configured (using persisted credentials)"
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

# Run pre-start hook if defined by child image
if [ -n "$RUNNER_PRE_START" ] && [ -f "$RUNNER_PRE_START" ]; then
    echo ""
    source "$RUNNER_PRE_START"
fi

echo ""
echo "=========================================="
echo "Starting GitHub Actions Runner..."
echo "=========================================="

# Cleanup function - don't remove runner on shutdown to allow restarts
# without needing a new token. To fully unregister, use:
# ./config.sh remove --token <token>
cleanup() {
    echo ""
    echo "Shutting down runner..."
}

trap cleanup SIGTERM SIGINT

# Run the runner
./run.sh &
wait $!
