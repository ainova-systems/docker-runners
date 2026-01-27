# 🔧 Build Runner

GitHub Actions self-hosted runner for **builds and tests** — no Docker dependency required.

[![Docker Image](https://img.shields.io/badge/docker-ghcr.io%2Fainova--systems%2Fdocker--runners%2Fbuild--runner-blue)](https://github.com/ainova-systems/docker-runners/pkgs/container/docker-runners%2Fbuild-runner)

## 🎯 Use Cases

- Compile .NET / Node.js applications
- Run unit and integration tests
- Lint and code analysis
- Generate build artifacts
- Database migrations (dotnet-ef)

## 📦 Tech Stack

Directly extends [base-runner](../base-runner/) with no additional tools:

**Inherited from base-runner:** Node.js 20, .NET 10, gh CLI, dotnet-ef, js-yaml

## 🔐 Security

This runner has **no Docker socket access**, making it safer for:
- Running untrusted code
- Multi-tenant environments
- Strict security policies

Use [docker-runner](../docker-runner/) when you need to build/push images.

## 🚀 Quick Start

### Option 1: Docker Run

```bash
docker run -d --name build-runner --restart unless-stopped \
  -e GITHUB_REPOSITORY_URL=https://github.com/your-org/your-repo \
  -e GITHUB_RUNNER_TOKEN=YOUR_TOKEN \
  -v build-runner-data:/home/runner/actions-runner \
  ghcr.io/ainova-systems/docker-runners/build-runner:latest
```

### Option 2: Docker Compose

```bash
cp .env.example .env
# Edit .env with your values
docker compose up -d
```

## ⚙️ Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GITHUB_REPOSITORY_URL` | ✅ | Full repository URL |
| `GITHUB_RUNNER_TOKEN` | ✅* | Runner registration token |
| `RUNNER_NAME` | ❌ | Custom runner name |
| `RUNNER_LABELS` | ❌ | Default: `self-hosted,build,dotnet,nodejs` |

*Only required for initial setup

## 🏷️ Runner Labels

Use these labels in your workflows:

```yaml
jobs:
  build:
    runs-on: [self-hosted, build]
    steps:
      - uses: actions/checkout@v4
      - run: dotnet build
      - run: dotnet test
```

Available labels:
- `self-hosted`
- `build`
- `dotnet`
- `nodejs`

## 📋 Commands

```bash
# View logs
docker logs build-runner -f

# Stop
docker stop build-runner

# Remove (keeps data)
docker rm -f build-runner

# Full reset (removes credentials)
docker rm -f build-runner && docker volume rm build-runner-data
```

## 🆚 build-runner vs docker-runner

| Feature | build-runner | docker-runner |
|---------|--------------|---------------|
| Build code | ✅ | ✅ |
| Run tests | ✅ | ✅ |
| Build Docker images | ❌ | ✅ |
| Deploy containers | ❌ | ✅ |
| Docker socket | ❌ No | ✅ Yes |
| Security | 🔒 Higher | ⚠️ Lower |

## 📄 License

MIT
