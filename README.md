# 🐳 Docker Runners for GitHub Actions

[![Build Status](https://github.com/ainova-systems/docker-runners/actions/workflows/build-runners.yml/badge.svg)](https://github.com/ainova-systems/docker-runners/actions/workflows/build-runners.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Pre-built, production-ready **GitHub Actions self-hosted runners** in Docker containers. Fork this repo to customize runners for your team's tech stack.

## 📦 Available Runners

| Runner | Description | Image |
|--------|-------------|-------|
| [**base-runner**](base-runner/) | Foundation image with Node.js, .NET, gh CLI | `ghcr.io/ainova-systems/docker-runners/base-runner` |
| [**ai-runner**](ai-runner/) | AI automation with Claude CLI & Cursor CLI | `ghcr.io/ainova-systems/docker-runners/ai-runner` |
| [**build-runner**](build-runner/) | Builds & tests without Docker socket | `ghcr.io/ainova-systems/docker-runners/build-runner` |
| [**docker-runner**](docker-runner/) | CI/CD with Docker CLI for container builds | `ghcr.io/ainova-systems/docker-runners/docker-runner` |

## 🚀 Quick Start

### One-Line Deploy (AI Runner)

```bash
docker run -d --name ai-runner --restart unless-stopped \
  -e GITHUB_REPOSITORY_URL=https://github.com/your-org/your-repo \
  -e GITHUB_RUNNER_TOKEN=YOUR_TOKEN \
  -e ANTHROPIC_API_KEY=sk-ant-xxx \
  -v ai-runner-data:/home/runner/actions-runner \
  ghcr.io/ainova-systems/docker-runners/ai-runner:latest
```

### One-Line Deploy (CI/CD Runner)

```bash
docker run -d --name docker-runner --restart unless-stopped \
  -e GITHUB_REPOSITORY_URL=https://github.com/your-org/your-repo \
  -e GITHUB_RUNNER_TOKEN=YOUR_TOKEN \
  -v docker-runner-data:/home/runner/actions-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/ainova-systems/docker-runners/docker-runner:latest
```

### One-Line Deploy (Build Runner)

```bash
docker run -d --name build-runner --restart unless-stopped \
  -e GITHUB_REPOSITORY_URL=https://github.com/your-org/your-repo \
  -e GITHUB_RUNNER_TOKEN=YOUR_TOKEN \
  -v build-runner-data:/home/runner/actions-runner \
  ghcr.io/ainova-systems/docker-runners/build-runner:latest
```

> 💡 **build-runner vs docker-runner**: Use build-runner for simple build/test jobs (no Docker socket = more secure). Use docker-runner only when you need to build Docker images.

## 🔑 Getting a Runner Token

1. Go to your repository → **Settings** → **Actions** → **Runners**
2. Click **New self-hosted runner**
3. Copy the token from the configure command

> ⚠️ Tokens expire in **1 hour**. Generate a new one if setup fails.

## 🍴 Fork & Customize

This repo is designed to be forked. Customize runners for your team:

### Step 1: Fork the Repository

```bash
# Fork on GitHub, then clone
git clone https://github.com/YOUR-ORG/docker-runners.git
cd docker-runners
```

### Step 2: Customize Base Runner

Edit `base-runner/Dockerfile` to add your team's dependencies:

```dockerfile
# Add Python
RUN apt-get update && apt-get install -y python3 python3-pip

# Add Go
ARG GO_VERSION=1.21
RUN wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz \
    && rm go${GO_VERSION}.linux-amd64.tar.gz
ENV PATH="${PATH}:/usr/local/go/bin"

# Add your global npm packages
RUN npm install -g pnpm turbo
```

### Step 3: Create Custom Runner (Optional)

Create a new runner extending base:

```dockerfile
# my-runner/Dockerfile
ARG BASE_IMAGE=ghcr.io/YOUR-ORG/docker-runners/base-runner:latest
FROM ${BASE_IMAGE}

USER root
RUN apt-get update && apt-get install -y your-tools
USER runner

ENV RUNNER_LABELS=self-hosted,my-runner
```

### Step 4: Update Image Registry

In `.github/workflows/build-runners.yml`, change:

```yaml
env:
  IMAGE_PREFIX: ghcr.io/YOUR-ORG/docker-runners
```

### Step 5: Push & Build

```bash
git add -A
git commit -m "Customized runners for our team"
git push origin main
# GitHub Actions will build and push images to your GHCR
```

## 🏗️ Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                        base-runner                             │
│  Ubuntu 24.04 │ Node.js 24 │ .NET 10 │ gh CLI │ Actions Runner │
└───────────────────────────────────────────────────────────────┘
         ▲                    ▲                    ▲
         │                    │                    │
    ┌────┴────┐         ┌─────┴─────┐        ┌────┴─────┐
    │ai-runner│         │build-runner│       │docker-runner│
    │Claude   │         │Labels only │       │Docker CLI │
    │Cursor   │         │No socket   │       │Compose    │
    └─────────┘         └───────────┘        └───────────┘
```

### Why "Heavy Base"?

We use a **single full-stack base image** pattern (similar to GitHub's official runners):

- ✅ **Simple to fork** — customize one Dockerfile, not a complex hierarchy
- ✅ **Fast child builds** — ai-runner and docker-runner only add their specific tools
- ✅ **Consistent environment** — all runners share the same Node.js, .NET versions
- ✅ **Easy maintenance** — update dependencies in one place

**Trade-off**: Base image includes Node.js + .NET even if you only need one. For most full-stack teams, this is acceptable. If you need minimal images, fork and remove unused tools from base-runner.

## 📋 Base Runner Tech Stack

| Component | Version | Purpose |
|-----------|---------|---------|
| Ubuntu | 24.04 LTS | Base OS |
| Node.js | 24.x | JavaScript runtime |
| .NET SDK | 10.0 | C# builds |
| GitHub CLI | latest | PR operations |
| dotnet-ef | latest | Database migrations |
| js-yaml | latest | YAML validation |
| GitHub Runner | 2.331.0 | Actions execution |

## 🔧 Build Args (Customizable)

Override versions when building:

```bash
docker build \
  --build-arg RUNNER_VERSION=2.320.0 \
  --build-arg NODE_MAJOR=22 \
  --build-arg DOTNET_VERSION=9.0 \
  -t my-base-runner:latest \
  base-runner/
```

## 📁 Repository Structure

```
docker-runners/
├── .github/workflows/
│   └── build-runners.yml      # CI pipeline: base → ai → build → docker
├── base-runner/               # 🔧 Customize this!
│   ├── Dockerfile             # Core dependencies
│   └── entrypoint.sh          # Startup script
├── ai-runner/                 # AI automation
│   ├── Dockerfile             # + Claude, Cursor CLI
│   ├── entrypoint.sh          # + API key handling
│   ├── docker-compose.yml     # Local development
│   ├── setup.sh               # One-line deploy
│   └── .env.example
├── build-runner/              # Builds & tests (no Docker socket)
│   ├── Dockerfile             # Labels only, no extra deps
│   ├── docker-compose.yml     # Local development
│   └── .env.example
├── docker-runner/             # Docker container builds
│   ├── Dockerfile             # + Docker CLI, Compose
│   ├── entrypoint.sh
│   ├── docker-compose.yml     # With Docker socket mount
│   ├── setup.sh               # One-line deploy
│   └── .env.example
└── README.md
```

## 🔄 Workflow Logic

The CI pipeline builds images in dependency order:

1. **base-runner changes** → Rebuild base + all child images
2. **ai-runner changes** → Rebuild only ai-runner
3. **build-runner changes** → Rebuild only build-runner
4. **docker-runner changes** → Rebuild only docker-runner
5. **Manual trigger** → Force rebuild all

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/add-python`)
3. Commit changes (`git commit -m "Added Python 3.12 to base runner"`)
4. Push to branch (`git push origin feature/add-python`)
5. Open a Pull Request

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

**Keywords**: GitHub Actions, self-hosted runner, Docker, CI/CD, DevOps, automation, Claude CLI, Cursor CLI, Node.js, .NET


