# 🤖 AI Runner

GitHub Actions self-hosted runner with **Claude CLI** and **Cursor CLI** for AI-powered automation.

[![Docker Image](https://img.shields.io/badge/docker-ghcr.io%2Fainova--systems%2Fdocker--runners%2Fai--runner-blue)](https://github.com/ainova-systems/docker-runners/pkgs/container/docker-runners%2Fai-runner)

## 🎯 Use Cases

- Automated code reviews with AI
- PR descriptions and summaries
- Code generation from issues
- Documentation generation
- Test case creation

## 📦 Tech Stack

Extends [base-runner](../base-runner/) with:

| Tool | Purpose |
|------|---------|
| Claude CLI | Anthropic AI code assistant |
| Cursor CLI | Cursor AI agent |

**Inherited from base-runner:** Node.js 24, .NET 10, gh CLI, dotnet-ef

## 🚀 Quick Start

### Step 1: Add GitHub Secrets

```bash
# Claude CLI - choose one:
gh secret set ANTHROPIC_API_KEY        # Option A: API key
gh secret set CLAUDE_CODE_OAUTH_TOKEN  # Option B: OAuth token (Pro/Max users)

# Cursor CLI:
gh secret set CURSOR_API_KEY
```

### Step 2: Deploy Runner

**Option A: Docker Run**

```bash
docker run -d --name ai-runner --restart unless-stopped \
  -e GITHUB_REPOSITORY_URL=https://github.com/your-org/your-repo \
  -e GITHUB_RUNNER_TOKEN=YOUR_TOKEN \
  -v ai-runner-data:/home/runner/actions-runner \
  ghcr.io/ainova-systems/docker-runners/ai-runner:latest
```

**Option B: Docker Compose**

```bash
cp .env.example .env
# Edit .env with your values
docker compose up -d
```

## ⚙️ Environment Variables

### Container Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GITHUB_REPOSITORY_URL` | ✅ | Full repository URL |
| `GITHUB_RUNNER_TOKEN` | ✅* | Runner registration token |
| `RUNNER_NAME` | ⚪ | Custom runner name |
| `RUNNER_LABELS` | ⚪ | Default: `self-hosted,claude-cli,cursor-agent` |

*Only required for initial setup (persisted in volume)

### GitHub Repository Secrets (Required)

| Secret | Required | Description |
|--------|----------|-------------|
| `ANTHROPIC_API_KEY` | ✅* | Claude API key from [Anthropic Console](https://console.anthropic.com/) |
| `CLAUDE_CODE_OAUTH_TOKEN` | ✅* | Claude OAuth token (alternative to API key) |
| `CURSOR_API_KEY` | ✅ | Cursor CLI API key |

*One of `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` required for Claude CLI

### Alternative: Container API Keys (Not Recommended)

For local dev only, you can pass API keys to container. See [API Key Management](#-api-key-management).

## 🏷️ Runner Labels

Use these labels in your workflows:

```yaml
jobs:
  ai-review:
    runs-on: [self-hosted, claude-cli]
    steps:
      - uses: actions/checkout@v4
      - run: claude "Review this PR for issues"
```

Available labels:
- `self-hosted`
- `claude-cli`
- `cursor-agent`

## 🔧 Customization

### Add More AI Tools

Fork and extend the Dockerfile:

```dockerfile
ARG BASE_IMAGE=ghcr.io/your-org/docker-runners/base-runner:latest
FROM ${BASE_IMAGE}

USER root

# Add OpenAI CLI
RUN pip install openai

# Add other AI tools
RUN npm install -g @anthropic-ai/claude-code

USER runner
```

### Custom Labels

```bash
-e RUNNER_LABELS=self-hosted,claude-cli,cursor-agent,my-custom-label
```

## 🔐 API Key Management

| Approach | When to Use | Setup |
|----------|-------------|-------|
| **GitHub Secrets** (Recommended) | Production | `gh secret set ANTHROPIC_API_KEY` |
| **Container Env Vars** | Local dev only | `-e ANTHROPIC_API_KEY=sk-ant-xxx` |

**GitHub Secrets** — keys are encrypted, audited, easy to rotate. Inject in workflow:

```yaml
env:
  ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
  CURSOR_API_KEY: ${{ secrets.CURSOR_API_KEY }}
```

**Container Env Vars** — simpler but less secure (keys visible in `docker inspect`).

## 🔐 Security Notes

- No secrets baked into image
- Runner credentials persist in volume after first setup
- Runner token only needed for initial registration

## 🏗️ Local Development

```bash
# Build locally
docker build -t ai-runner:local .

# Run local build
docker run -d --name ai-runner-dev \
  -e GITHUB_REPOSITORY_URL=... \
  -e GITHUB_RUNNER_TOKEN=... \
  -e ANTHROPIC_API_KEY=... \
  ai-runner:local
```

## 📄 License

MIT
