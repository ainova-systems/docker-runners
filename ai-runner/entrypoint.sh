#!/bin/bash
set -e

# AI Automation Runner Entrypoint
# This script configures and starts the GitHub Actions runner

echo "=========================================="
echo "AI Automation Runner v1.1"
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

# Check for authentication
if [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    echo "INFO: No Claude auth in container environment"
    echo "      API keys provided via GitHub secrets (ANTHROPIC_API_KEY or CLAUDE_CODE_OAUTH_TOKEN)"
fi

# Export authentication for Claude CLI
if [ -n "$ANTHROPIC_API_KEY" ]; then
    export ANTHROPIC_API_KEY
    echo "Claude CLI: Using ANTHROPIC_API_KEY from container"
elif [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    export CLAUDE_CODE_OAUTH_TOKEN
    echo "Claude CLI: Using CLAUDE_CODE_OAUTH_TOKEN from container"
fi

# Export authentication for Cursor CLI
if [ -n "$CURSOR_API_KEY" ]; then
    export CURSOR_API_KEY
    echo "Cursor CLI: Using CURSOR_API_KEY from container"
else
    echo "Cursor CLI: No container API key (use GitHub secrets)"
fi

# Set runner name
RUNNER_NAME=${RUNNER_NAME:-"ai-runner-$(hostname)"}

# Set runner labels
LABELS=${RUNNER_LABELS:-"self-hosted,claude-cli,cursor-agent"}

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

# Verify Claude CLI
echo "Verifying Claude CLI installation..."
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
    echo "Claude CLI version: $CLAUDE_VERSION"
else
    echo "WARNING: Claude CLI not found in PATH"
fi

# Verify/Install Cursor CLI
echo "Verifying Cursor CLI installation..."
if command -v cursor-agent &> /dev/null; then
    CURSOR_VERSION=$(cursor-agent --version 2>/dev/null || echo "unknown")
    echo "Cursor CLI version: $CURSOR_VERSION"
else
    echo "Cursor CLI not found, attempting installation..."
    NO_COLOR=1 bash -c "$(curl -fsSL https://cursor.com/install)" || echo "WARNING: Cursor CLI installation failed"
    # Add to PATH if installed to user directory
    if [ -f "$HOME/.local/bin/cursor-agent" ]; then
        export PATH="$PATH:$HOME/.local/bin"
        echo "Cursor CLI installed to $HOME/.local/bin"
    fi
fi

echo ""
echo "Verifying installed tools..."
echo "  Node.js:    $(node --version)"
echo "  npm:        $(npm --version)"
echo "  .NET SDK:   $(dotnet --version)"
echo "  dotnet-ef:  $(dotnet ef --version 2>/dev/null || echo 'not installed')"
echo "  git:        $(git --version | cut -d' ' -f3)"
echo "  gh CLI:     $(gh --version | head -1 | cut -d' ' -f3)"
echo "  docker:     $(docker --version | cut -d' ' -f3 | tr -d ',')"
echo "  ripgrep:    $(rg --version | head -1 | cut -d' ' -f2)"
echo "  jq:         $(jq --version)"
echo "  Claude CLI: $(claude --version 2>/dev/null || echo 'not found')"
echo "  Cursor CLI: $(cursor-agent --version 2>/dev/null || echo 'not found')"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo "Shutting down runner..."
    # Note: We don't remove the runner config on shutdown to allow restarts
    # without needing a new token. To fully unregister, use:
    # ./config.sh remove --token <token>
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
