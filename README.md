# OpenClaw Agent Browser

Remote browser control for OpenClaw via CDP (Chrome DevTools Protocol).

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/servas-ai/openclaw-agent-browser/main/install.sh | bash
```

Or clone and run:
```bash
git clone https://github.com/servas-ai/openclaw-agent-browser.git
cd openclaw-agent-browser
bash install.sh
```

## What it does

1. **Lets you pick your browser** — Brave, Chrome, Chromium, Edge, or Arc
2. **Starts it with CDP** remote debugging (port 9222)
3. **Sets up socat bridge** (Linux) for remote access
4. **Tests connectivity** to your OpenClaw server
5. **Creates systemd service** for auto-start on boot

## Requirements

- **Tailscale** — both machines must be connected
- **Chromium-based browser** — Brave, Chrome, Chromium, Edge, or Arc
- **Node.js** (auto-installed if missing)

## After Install

```bash
# Start browser
~/.openclaw-agent-browser/start-browser.sh

# Test connection  
~/.openclaw-agent-browser/test-connection.sh

# Stop browser
~/.openclaw-agent-browser/stop-browser.sh

# Connect from OpenClaw
openclaw browser connect <TAILSCALE-IP>:9222
```

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `OPENCLAW_SERVER` | `100.120.120.120` | OpenClaw server Tailscale IP |
| `CDP_PORT` | `9222` | CDP debugging port |
| `INSTALL_DIR` | `~/.openclaw-agent-browser` | Installation directory |

## License

MIT © servas-ai
