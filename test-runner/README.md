# 🧪 Test Runner

GitHub Actions self-hosted runner with **Playwright** and **Chromium** for automated E2E browser testing.

[![Docker Image](https://img.shields.io/badge/docker-ghcr.io%2Fainova--systems%2Fdocker--runners%2Ftest--runner-blue)](https://github.com/ainova-systems/docker-runners/pkgs/container/docker-runners%2Ftest-runner)

## Use Cases

- E2E smoke tests on PR preview environments
- Visual regression testing with Playwright screenshots
- Frontend verification after deployment
- Browser-based integration testing

## Tech Stack

Extends [base-runner](../base-runner/) with:

| Tool | Purpose |
|------|---------|
| Playwright | Browser automation and E2E testing framework |
| Chromium | Headless browser for test execution |

**Inherited from base-runner:** Node.js 24, .NET 10, gh CLI, dotnet-ef

## Quick Start

### Deploy Runner

**Option A: Docker Run**

```bash
docker run -d --name test-runner --restart unless-stopped \
  -e GITHUB_REPOSITORY_URL=https://github.com/your-org/your-repo \
  -e GITHUB_RUNNER_TOKEN=YOUR_TOKEN \
  -v test-runner-data:/home/runner/actions-runner \
  ghcr.io/ainova-systems/docker-runners/test-runner:latest
```

**Option B: Docker Compose**

```bash
cp .env.example .env
# Edit .env with your values
docker compose up -d
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GITHUB_REPOSITORY_URL` | Yes | Full repository URL |
| `GITHUB_RUNNER_TOKEN` | Yes* | Runner registration token |
| `RUNNER_NAME` | No | Custom runner name |
| `RUNNER_LABELS` | No | Default: `self-hosted,e2e-tests,playwright` |

*Only required for initial setup (persisted in volume)

## Runner Labels

Use these labels in your workflows:

```yaml
jobs:
  e2e-tests:
    runs-on: [self-hosted, e2e-tests]
    steps:
      - uses: actions/checkout@v4
      - run: npx playwright test
```

Available labels:
- `self-hosted`
- `e2e-tests`
- `playwright`

## Playwright Configuration

Playwright browsers are pre-installed at `/opt/playwright-browsers`. Set the environment variable in your workflow:

```yaml
env:
  PLAYWRIGHT_BROWSERS_PATH: /opt/playwright-browsers
```

Only **Chromium** is pre-installed to keep the image small. To add Firefox or WebKit, extend the Dockerfile:

```dockerfile
RUN npx playwright install firefox webkit
```

## Security Notes

- No secrets baked into image
- Runner credentials persist in volume after first setup
- Runner token only needed for initial registration
- No Docker socket required (safer than docker-runner)

## Local Development

```bash
# Build locally
docker build -t test-runner:local .

# Run local build
docker run -d --name test-runner-dev \
  -e GITHUB_REPOSITORY_URL=... \
  -e GITHUB_RUNNER_TOKEN=... \
  test-runner:local
```

## License

MIT
