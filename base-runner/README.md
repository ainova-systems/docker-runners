# 🔧 Base Runner

Foundation image for all GitHub Actions self-hosted runners. **Fork and customize this for your team's tech stack.**

[![Docker Image](https://img.shields.io/badge/docker-ghcr.io%2Fainova--systems%2Fdocker--runners%2Fbase--runner-blue)](https://github.com/ainova-systems/docker-runners/pkgs/container/docker-runners%2Fbase-runner)

## 📦 Included Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Ubuntu | 24.04 LTS | Base operating system |
| Node.js | 24.x LTS | JavaScript runtime |
| .NET SDK | 10.0 | C# compilation |
| GitHub CLI | latest | PR/Issue operations |
| dotnet-ef | latest | EF Core migrations |
| js-yaml | latest | YAML validation |
| ripgrep | latest | Fast code search |
| GitHub Runner | 2.331.0 | Actions execution |

## 🎯 Design Philosophy

This image is intentionally **minimal but complete**:

- ✅ Common dev tools (Node, .NET, Git)
- ✅ GitHub integration (gh CLI, runner)
- ✅ Build essentials for native modules
- ❌ No language-specific frameworks
- ❌ No deployment tools

Child images (ai-runner, docker-runner) add specialized tools.

## 🍴 Customization Guide

### Option 1: Modify Base Directly

Best for team-wide dependencies (Python, Go, etc.):

```dockerfile
# base-runner/Dockerfile

# Add after existing apt-get install:
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    golang-go

# Add after npm install:
RUN npm install -g pnpm turbo yarn
```

### Option 2: Create New Child Image

Best for role-specific runners:

```dockerfile
# python-runner/Dockerfile
ARG BASE_IMAGE=ghcr.io/your-org/docker-runners/base-runner:latest
FROM ${BASE_IMAGE}

USER root

# Python with data science stack
RUN apt-get update && apt-get install -y python3 python3-pip python3-venv
RUN pip3 install numpy pandas scikit-learn

USER runner
ENV RUNNER_LABELS=self-hosted,python,data-science
```

### Option 3: Override Versions

Use build args for different versions:

```bash
docker build \
  --build-arg RUNNER_VERSION=2.320.0 \
  --build-arg NODE_MAJOR=22 \
  --build-arg DOTNET_VERSION=9.0 \
  -t my-base:latest \
  base-runner/
```

## 🔧 Available Build Args

| Arg | Default | Description |
|-----|---------|-------------|
| `RUNNER_VERSION` | 2.331.0 | GitHub Actions runner version |
| `NODE_MAJOR` | 24 | Node.js major version |
| `DOTNET_VERSION` | 10.0 | .NET SDK channel |

## 📁 File Structure

```
base-runner/
├── Dockerfile      # Main image definition
└── entrypoint.sh   # Startup script (runner config & start)
```

## 🔄 Entrypoint Behavior

The `entrypoint.sh` script:

1. Validates required env vars (`GITHUB_REPOSITORY_URL`, `GITHUB_RUNNER_TOKEN`)
2. Configures runner on first start (saves to volume)
3. Reuses existing config on subsequent starts
4. Handles graceful shutdown (removes runner registration)

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GITHUB_REPOSITORY_URL` | ✅ | Full repository URL |
| `GITHUB_RUNNER_TOKEN` | ✅* | Runner registration token |
| `RUNNER_NAME` | ❌ | Custom runner name |
| `RUNNER_LABELS` | ❌ | Comma-separated labels |

*Only required for initial configuration

## 🏗️ Local Development

```bash
# Build base image
docker build -t base-runner:local base-runner/

# Test with a simple job
docker run --rm -it \
  -e GITHUB_REPOSITORY_URL=https://github.com/your/repo \
  -e GITHUB_RUNNER_TOKEN=YOUR_TOKEN \
  base-runner:local
```

## ➕ Adding Dependencies

### System Packages (apt)

```dockerfile
RUN apt-get update && apt-get install -y \
    package1 \
    package2 \
    && rm -rf /var/lib/apt/lists/*
```

### Node.js Global Packages

```dockerfile
RUN npm install -g package1 package2
```

### .NET Tools

```dockerfile
RUN dotnet tool install --global tool-name
ENV PATH="${PATH}:/root/.dotnet/tools"
```

### Python (if added)

```dockerfile
RUN pip3 install package1 package2
```

## 🔐 Security Notes

- Runner executes as non-root `runner` user
- `runner` has passwordless sudo (for tool installation during jobs)
- No secrets baked into image
- All credentials passed at runtime

## 📄 License

MIT



