#!/bin/bash
# AI Runner pre-start hook — sourced by base entrypoint via RUNNER_PRE_START

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

# Verify/Install Cursor CLI (fallback if not in image)
if ! command -v cursor-agent &> /dev/null; then
    echo "Cursor CLI not found, attempting installation..."
    NO_COLOR=1 bash -c "$(curl -fsSL https://cursor.com/install)" || echo "WARNING: Cursor CLI installation failed"
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
echo "  docker:     $(docker --version | cut -d' ' -f3 | tr -d ',' 2>/dev/null || echo 'not installed')"
echo "  ripgrep:    $(rg --version | head -1 | cut -d' ' -f2)"
echo "  jq:         $(jq --version)"
echo "  Claude CLI: $(claude --version 2>/dev/null || echo 'not found')"
echo "  Cursor CLI: $(cursor-agent --version 2>/dev/null || echo 'not found')"
