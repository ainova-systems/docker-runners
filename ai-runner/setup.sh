#!/bin/bash
set -e

# AI Runner - One-line Setup Script
#
# Usage:
#   curl -sSL <script-url> | bash -s -- \
#     --repo https://github.com/org/repo \
#     --token RUNNER_TOKEN \
#     --anthropic-key sk-ant-xxx \
#     [--name runner-name] \
#     [--image ghcr.io/ainova-systems/docker-runners/ai-runner:latest]

# Default image from GHCR
DEFAULT_IMAGE="ghcr.io/ainova-systems/docker-runners/ai-runner:latest"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}"
echo "=========================================="
echo "  AI Runner Setup"
echo "  Tech Stack: Claude CLI, Cursor CLI"
echo "=========================================="
echo -e "${NC}"

# Parse arguments
REPO_URL=""
TOKEN=""
ANTHROPIC_KEY=""
CURSOR_KEY=""
RUNNER_NAME="ai-runner"
LABELS="self-hosted,claude-cli,cursor-cli"
IMAGE="$DEFAULT_IMAGE"

while [[ $# -gt 0 ]]; do
    case $1 in
        --repo) REPO_URL="$2"; shift 2 ;;
        --token) TOKEN="$2"; shift 2 ;;
        --anthropic-key) ANTHROPIC_KEY="$2"; shift 2 ;;
        --cursor-key) CURSOR_KEY="$2"; shift 2 ;;
        --name) RUNNER_NAME="$2"; shift 2 ;;
        --labels) LABELS="$2"; shift 2 ;;
        --image) IMAGE="$2"; shift 2 ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
    esac
done

# Interactive mode if arguments not provided
if [ -z "$REPO_URL" ]; then
    echo -n "GitHub Repository URL: "
    read REPO_URL
fi

if [ -z "$TOKEN" ]; then
    echo -n "Runner Token (from GitHub Settings -> Actions -> Runners): "
    read -s TOKEN
    echo ""
fi

if [ -z "$ANTHROPIC_KEY" ]; then
    echo -n "Anthropic API Key (sk-ant-...): "
    read -s ANTHROPIC_KEY
    echo ""
fi

echo -n "Cursor API Key (optional, press Enter to skip): "
read -s CURSOR_KEY
echo ""

echo -n "Runner Name [$RUNNER_NAME]: "
read input
RUNNER_NAME=${input:-$RUNNER_NAME}

# Validate
if [ -z "$REPO_URL" ] || [ -z "$TOKEN" ]; then
    echo -e "${RED}ERROR: Repository URL and Token are required${NC}"
    exit 1
fi

if [ -z "$ANTHROPIC_KEY" ]; then
    echo -e "${YELLOW}WARNING: No Anthropic API key provided. Claude CLI won't work.${NC}"
fi

echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Repository: $REPO_URL"
echo "  Runner Name: $RUNNER_NAME"
echo "  Labels: $LABELS"
echo "  Image: $IMAGE"
echo "  Anthropic Key: ${ANTHROPIC_KEY:+***configured***}"
echo "  Cursor Key: ${CURSOR_KEY:+***configured***}"
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: Docker is not installed${NC}"
    echo "Install Docker first: https://docs.docker.com/engine/install/"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}ERROR: Docker daemon is not running or you don't have permission${NC}"
    echo "Try: sudo usermod -aG docker \$USER && newgrp docker"
    exit 1
fi

# Pull image
echo -e "${GREEN}Pulling image from registry...${NC}"
docker pull "$IMAGE"

# Stop existing container if running
if docker ps -a --format '{{.Names}}' | grep -q "^${RUNNER_NAME}$"; then
    echo -e "${YELLOW}Stopping existing container...${NC}"
    docker stop "$RUNNER_NAME" 2>/dev/null || true
    docker rm "$RUNNER_NAME" 2>/dev/null || true
fi

# Create volume for persistence
docker volume create "${RUNNER_NAME}-data" 2>/dev/null || true

# Run container
echo -e "${GREEN}Starting runner...${NC}"
docker run -d \
    --name "$RUNNER_NAME" \
    --restart unless-stopped \
    -e GITHUB_REPOSITORY_URL="$REPO_URL" \
    -e GITHUB_RUNNER_TOKEN="$TOKEN" \
    -e RUNNER_NAME="$RUNNER_NAME" \
    -e RUNNER_LABELS="$LABELS" \
    -e ANTHROPIC_API_KEY="$ANTHROPIC_KEY" \
    -e CURSOR_API_KEY="$CURSOR_KEY" \
    -v "${RUNNER_NAME}-data:/home/runner/actions-runner" \
    "$IMAGE"

echo ""
echo -e "${GREEN}=========================================="
echo "  AI Runner started successfully!"
echo "==========================================${NC}"
echo ""
echo "Commands:"
echo "  View logs:    docker logs $RUNNER_NAME -f"
echo "  Stop:         docker stop $RUNNER_NAME"
echo "  Remove:       docker rm -f $RUNNER_NAME"
echo "  Full reset:   docker rm -f $RUNNER_NAME && docker volume rm ${RUNNER_NAME}-data"
echo ""
echo "Check runner status in GitHub:"
echo "  $REPO_URL/settings/actions/runners"
