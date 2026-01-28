# 🔨 Docker Runner

GitHub Actions self-hosted runner with **Docker CLI** for building images and deploying containers.

[![Docker Image](https://img.shields.io/badge/docker-ghcr.io%2Fainova--systems%2Fdocker--runners%2Fdocker--runner-blue)](https://github.com/ainova-systems/docker-runners/pkgs/container/docker-runners%2Fdocker-runner)

## 🎯 Use Cases

- Build and push Docker images
- Deploy preview environments
- Run integration tests in containers
- Manage Docker Compose stacks
- Blue-green deployments

## 📦 Tech Stack

Extends [base-runner](../base-runner/) with:

| Tool | Purpose |
|------|---------|
| Docker CLI | Build and manage containers |
| Docker Compose | Multi-container orchestration |

**Inherited from base-runner:** Node.js 24, .NET 10, gh CLI, dotnet-ef

## 🚀 Quick Start

### Option 1: Docker Run

```bash
docker run -d --name docker-runner --restart unless-stopped \
  -e GITHUB_REPOSITORY_URL=https://github.com/your-org/your-repo \
  -e GITHUB_RUNNER_TOKEN=YOUR_TOKEN \
  -v docker-runner-data:/home/runner/actions-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/ainova-systems/docker-runners/docker-runner:latest
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
| `RUNNER_LABELS` | ❌ | Default: `self-hosted,docker,dotnet,nodejs` |

*Only required for initial setup

## 🐳 Docker Socket

This runner mounts `/var/run/docker.sock` to enable:

- `docker build` - Build images
- `docker push` - Push to registries
- `docker compose up` - Deploy stacks
- `docker run` - Run containers

### Security Consideration

Mounting Docker socket gives the runner full Docker access on the host. Use only on trusted repositories.

## 🏷️ Runner Labels

Use these labels in your workflows:

```yaml
jobs:
  build:
    runs-on: [self-hosted, docker]
    steps:
      - uses: actions/checkout@v4
      - run: docker build -t myapp:${{ github.sha }} .
      - run: docker push myapp:${{ github.sha }}
```

Available labels:
- `self-hosted`
- `docker`
- `dotnet`
- `nodejs`

## 🔧 Customization

### Add Registry Authentication

For private registries, add to your workflow:

```yaml
- name: Login to GHCR
  run: echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
```

### Add More Build Tools

Fork and extend the Dockerfile:

```dockerfile
ARG BASE_IMAGE=ghcr.io/your-org/docker-runners/base-runner:latest
FROM ${BASE_IMAGE}

USER root

# Add Kubernetes tools
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Add Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

USER runner
```

### Custom Labels

```bash
-e RUNNER_LABELS=self-hosted,docker,kubernetes,production
```

## 🏗️ Local Development

```bash
# Build locally
docker build -t docker-runner:local .

# Run local build
docker run -d --name docker-runner-dev \
  -e GITHUB_REPOSITORY_URL=... \
  -e GITHUB_RUNNER_TOKEN=... \
  -v /var/run/docker.sock:/var/run/docker.sock \
  docker-runner:local
```

## 🔄 Example Workflow

```yaml
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: [self-hosted, docker]
    steps:
      - uses: actions/checkout@v4
      
      - name: Build image
        run: docker build -t myapp:${{ github.sha }} .
      
      - name: Push to registry
        run: |
          echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
          docker tag myapp:${{ github.sha }} ghcr.io/${{ github.repository }}:${{ github.sha }}
          docker push ghcr.io/${{ github.repository }}:${{ github.sha }}
      
      - name: Deploy
        run: |
          docker compose -f docker-compose.prod.yml pull
          docker compose -f docker-compose.prod.yml up -d
```

## 📄 License

MIT

