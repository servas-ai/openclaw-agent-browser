---
name: agent-browser
description: "Remote browser control via CDP. Install on a Tailscale-connected PC, then connect from OpenClaw via agent-browser.connect {{AGENT_BROWSER_HOST}}:{{CDP_PORT}}."
metadata:
  openclaw:
    emoji: "🌐"
---

# Agent Browser Skill

Remote Chromium-based browser (Brave, Chrome, etc.) on a Tailscale-connected PC, controllable via CDP at `http://{{AGENT_BROWSER_HOST}}:{{CDP_PORT}}`.

## Installation (auf dem Ziel-PC)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/servas-ai/openclaw-agent-browser/main/install.sh)
```

Das Script fragt nach dem Browser (Brave/Chrome/Chromium/Edge/Arc), startet CDP, richtet socat-Bridge ein und testet die Verbindung.

## Connect via Playwright

```javascript
const { chromium } = require('playwright');
const browser = await chromium.connectOverCDP('http://{{AGENT_BROWSER_HOST}}:{{CDP_PORT}}');
const page = browser.contexts()[0].pages()[0] || await browser.contexts()[0].newPage();
await page.goto('https://example.com');
const title = await page.title();
```

## Connect via OpenClaw CLI

```bash
openclaw browser connect {{AGENT_BROWSER_HOST}}:{{CDP_PORT}}
```

## Check Status

```bash
curl -s http://{{AGENT_BROWSER_HOST}}:{{CDP_PORT}}/json/version | jq '.Browser'
```

## List Open Tabs

```bash
curl -s http://{{AGENT_BROWSER_HOST}}:{{CDP_PORT}}/json/list | jq '.[].url'
```

## Navigate a Tab

```bash
# Get first tab's WebSocket URL
WS=$(curl -s http://{{AGENT_BROWSER_HOST}}:{{CDP_PORT}}/json/list | jq -r '.[0].webSocketDebuggerUrl')
echo "Connect Playwright to: $WS"
```

## Screenshot via Playwright

```javascript
const page = browser.contexts()[0].pages()[0];
await page.screenshot({ path: '/tmp/screenshot.png', fullPage: true });
```

## Tips for AI Agents

- CDP port is 9222 by default, configurable via `CDP_PORT` env var
- socat bridge runs on Linux to make CDP accessible over Tailscale
- On macOS, CDP is directly accessible over the network
- Use `connectOverCDP` (not `connect`) for Chromium-based browsers
- The browser profile persists in `~/.openclaw-agent-browser/profile`
- Restart with `~/.openclaw-agent-browser/start-browser.sh`
