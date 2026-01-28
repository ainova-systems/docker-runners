#!/bin/bash
set -e

echo "=========================================="
echo "Docker Runner v1.0"
echo "Tech Stack: .NET 10, Node.js 24, Docker"
echo "=========================================="

# Validate required environment variables
if [ -z "$GITHUB_REPOSITORY_URL" ]; then
    echo "ERROR: GITHUB_REPOSITORY_URL is required"
    echo "Example: https://github.com/your-org/your-repo"
    exit 1
fi

if [ -z "$GITHUB_RUNNER_TOKEN" ] && [ ! -f ".credentials" ]; then
    echo "ERROR: GITHUB_RUNNER_TOKEN is required for initial configuration"
    echo "Get it from: Repository -> Settings -> Actions -> Runners -> New self-hosted runner"
    exit 1
fi

# Set runner name
RUNNER_NAME=${RUNNER_NAME:-"docker-runner-$(hostname)"}

# Set runner labels
LABELS=${RUNNER_LABELS:-"self-hosted,docker,dotnet,nodejs"}

echo ""
echo "Configuration:"
echo "  Repository: $GITHUB_REPOSITORY_URL"
echo "  Runner Name: $RUNNER_NAME"
echo "  Labels: $LABELS"
echo ""

# Configure runner if not already configured
if [ ! -f ".runner" ]; then
    echo "Configuring runner for first time..."
    
    ./config.sh \
        --url "$GITHUB_REPOSITORY_URL" \
        --token "$GITHUB_RUNNER_TOKEN" \
        --name "$RUNNER_NAME" \
        --labels "$LABELS" \
        --unattended \
        --replace
    
    echo "Runner configured successfully"
else
    echo "Runner already configured, using existing configuration"
fi

echo ""
echo "=========================================="
echo "Starting GitHub Actions Runner..."
echo "=========================================="

# Cleanup function
cleanup() {
    echo ""
    echo "Received shutdown signal, removing runner..."
    ./config.sh remove --token "$GITHUB_RUNNER_TOKEN" || true
}

trap cleanup SIGTERM SIGINT

# Run the runner
./run.sh &
wait $!

