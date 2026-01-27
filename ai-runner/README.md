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

**Inherited from base-runner:** Node.js 20, .NET 10, gh CLI, dotnet-ef

## 🚀 Quick Start

### Option 1: Docker Run

```bash
docker run -d --name ai-runner --restart unless-stopped \
  -e GITHUB_REPOSITORY_URL=https://github.com/your-org/your-repo \
  -e GITHUB_RUNNER_TOKEN=YOUR_TOKEN \
  -e ANTHROPIC_API_KEY=sk-ant-xxx \
  -v ai-runner-data:/home/runner/actions-runner \
  ghcr.io/ainova-systems/docker-runners/ai-runner:latest
```

### Option 2: Docker Compose

```bash
cp .env.example .env
# Edit .env with your values
docker compose up -d
```

### Option 3: Interactive Setup

```bash
curl -sSL https://raw.githubusercontent.com/ainova-systems/docker-runners/main/ai-runner/setup.sh | bash
```

## ⚙️ Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GITHUB_REPOSITORY_URL` | ✅ | Full repository URL |
| `GITHUB_RUNNER_TOKEN` | ✅* | Runner registration token |
| `ANTHROPIC_API_KEY` | ✅** | Claude API key |
| `CLAUDE_CODE_OAUTH_TOKEN` | ✅** | OAuth token (alternative) |
| `CURSOR_API_KEY` | ❌ | Cursor CLI API key |
| `RUNNER_NAME` | ❌ | Custom runner name |
| `RUNNER_LABELS` | ❌ | Default: `self-hosted,claude-cli,cursor-agent` |

*Only required for initial setup  
**One of `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` required

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

## 📋 Commands

```bash
# View logs
docker logs ai-runner -f

# Stop
docker stop ai-runner

# Restart
docker restart ai-runner

# Remove (keeps data)
docker rm -f ai-runner

# Full reset (removes credentials)
docker rm -f ai-runner && docker volume rm ai-runner-data
```

## 🔐 Security Notes

- API keys are passed as environment variables at runtime
- No secrets are baked into the image
- Credentials persist in the Docker volume after first setup
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
