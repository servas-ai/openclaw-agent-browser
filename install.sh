#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  OpenClaw Agent Browser — Installer                            ║
# ║  Installs CDP-based browser control on a Tailscale machine     ║
# ║  and connects it to the OpenClaw server.                       ║
# ╚══════════════════════════════════════════════════════════════════╝
set -euo pipefail

# ── Config ──────────────────────────────────────────────────────────
OPENCLAW_SERVER="${OPENCLAW_SERVER:-100.120.120.120}"
OPENCLAW_PORT="${OPENCLAW_PORT:-18789}"
CDP_PORT="${CDP_PORT:-9222}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.openclaw-agent-browser}"

# ── Colors ──────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

log()  { echo -e "${CYAN}[agent-browser]${NC} $1"; }
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; }

# ── Banner ──────────────────────────────────────────────────────────
echo -e "${BOLD}${BLUE}"
echo "╔══════════════════════════════════════════════════╗"
echo "║   OpenClaw Agent Browser Installer  v1.0        ║"
echo "║   Remote browser control via Playwright CDP     ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── OS Detection ────────────────────────────────────────────────────
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OS="linux"
fi
log "Detected OS: ${BOLD}$OS${NC}"

# ── Browser Selection ───────────────────────────────────────────────
echo ""
echo -e "${BOLD}Select your browser:${NC}"
echo ""

declare -A BROWSER_PATHS
declare -A BROWSER_NAMES

if [[ "$OS" == "macos" ]]; then
  BROWSER_PATHS=(
    [1]="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
    [2]="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    [3]="/Applications/Chromium.app/Contents/MacOS/Chromium"
    [4]="/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
    [5]="/Applications/Arc.app/Contents/MacOS/Arc"
  )
else
  BROWSER_PATHS=(
    [1]="brave-browser"
    [2]="google-chrome"
    [3]="chromium-browser"
    [4]="microsoft-edge"
    [5]="chromium"
  )
fi

BROWSER_NAMES=(
  [1]="Brave"
  [2]="Google Chrome"
  [3]="Chromium"
  [4]="Microsoft Edge"
  [5]="Arc (macOS only)"
)

for i in 1 2 3 4 5; do
  path="${BROWSER_PATHS[$i]}"
  name="${BROWSER_NAMES[$i]}"
  if [[ "$OS" == "macos" ]]; then
    if [[ -f "$path" ]]; then
      echo -e "  ${GREEN}[$i]${NC} $name ${GREEN}(found)${NC}"
    else
      echo -e "  ${RED}[$i]${NC} $name ${RED}(not found)${NC}"
    fi
  else
    if command -v "$path" &>/dev/null; then
      echo -e "  ${GREEN}[$i]${NC} $name ${GREEN}(found)${NC}"
    else
      echo -e "  ${RED}[$i]${NC} $name ${RED}(not found)${NC}"
    fi
  fi
done
echo ""

read -p "Enter number (1-5): " BROWSER_CHOICE
BROWSER_CHOICE="${BROWSER_CHOICE:-1}"

BROWSER_CMD="${BROWSER_PATHS[$BROWSER_CHOICE]}"
BROWSER_NAME="${BROWSER_NAMES[$BROWSER_CHOICE]}"
log "Selected: ${BOLD}$BROWSER_NAME${NC}"

# ── Check Tailscale ─────────────────────────────────────────────────
echo ""
log "Checking Tailscale..."
if command -v tailscale &>/dev/null; then
  TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "unknown")
  ok "Tailscale active — IP: ${BOLD}$TAILSCALE_IP${NC}"
else
  err "Tailscale not found! Install it first: https://tailscale.com/download"
  exit 1
fi

# ── Check connectivity to OpenClaw ──────────────────────────────────
log "Checking connectivity to OpenClaw at $OPENCLAW_SERVER..."
if curl -s --connect-timeout 5 "http://$OPENCLAW_SERVER:8008/health" &>/dev/null; then
  ok "OpenClaw server reachable"
else
  warn "Cannot reach OpenClaw server at $OPENCLAW_SERVER — check Tailscale"
fi

# ── Install Directory ───────────────────────────────────────────────
echo ""
log "Creating install directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# ── Install Node.js if needed ───────────────────────────────────────
if ! command -v node &>/dev/null; then
  log "Installing Node.js..."
  if [[ "$OS" == "macos" ]]; then
    brew install node
  else
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
  fi
fi
ok "Node.js $(node -v)"

# ── Install socat if needed (Linux) ─────────────────────────────────
if [[ "$OS" == "linux" ]] && ! command -v socat &>/dev/null; then
  log "Installing socat..."
  sudo apt-get install -y socat
fi

# ── Create launcher script ──────────────────────────────────────────
log "Creating browser launcher..."
cat > "$INSTALL_DIR/start-browser.sh" << LAUNCHER
#!/bin/bash
# Launch browser with CDP remote debugging
BROWSER_CMD="$BROWSER_CMD"
CDP_PORT=$CDP_PORT

echo "Starting \$BROWSER_CMD with CDP on port \$CDP_PORT..."

if [[ "$OS" == "macos" ]]; then
  "\$BROWSER_CMD" \\
    --remote-debugging-port=\$CDP_PORT \\
    --no-first-run \\
    --no-default-browser-check \\
    --user-data-dir="$INSTALL_DIR/browser-profile" &
else
  \$BROWSER_CMD \\
    --remote-debugging-port=\$CDP_PORT \\
    --no-first-run \\
    --no-default-browser-check \\
    --user-data-dir="$INSTALL_DIR/browser-profile" &
fi

BROWSER_PID=\$!
echo "Browser PID: \$BROWSER_PID"
echo \$BROWSER_PID > "$INSTALL_DIR/browser.pid"

# Wait for CDP
for i in {1..15}; do
  if curl -s http://localhost:\$CDP_PORT/json/version &>/dev/null; then
    echo "✅ CDP ready on port \$CDP_PORT"
    break
  fi
  sleep 1
done

# Start socat bridge (Linux only, for remote access)
if [[ "\$(uname)" != "Darwin" ]]; then
  pkill -f "socat.*\$CDP_PORT" 2>/dev/null || true
  socat TCP4-LISTEN:\$CDP_PORT,fork,reuseaddr,bind=0.0.0.0 TCP4:127.0.0.1:\$CDP_PORT &
  echo "socat bridge active on 0.0.0.0:\$CDP_PORT"
fi
LAUNCHER
chmod +x "$INSTALL_DIR/start-browser.sh"

# ── Create stop script ──────────────────────────────────────────────
cat > "$INSTALL_DIR/stop-browser.sh" << 'STOPPER'
#!/bin/bash
if [[ -f "$HOME/.openclaw-agent-browser/browser.pid" ]]; then
  kill $(cat "$HOME/.openclaw-agent-browser/browser.pid") 2>/dev/null
  rm "$HOME/.openclaw-agent-browser/browser.pid"
  echo "Browser stopped"
fi
pkill -f "socat.*9222" 2>/dev/null || true
echo "socat bridge stopped"
STOPPER
chmod +x "$INSTALL_DIR/stop-browser.sh"

# ── Create connect-test script ──────────────────────────────────────
cat > "$INSTALL_DIR/test-connection.sh" << TESTER
#!/bin/bash
CDP_PORT=$CDP_PORT
OPENCLAW_SERVER=$OPENCLAW_SERVER
TAILSCALE_IP=\$(tailscale ip -4 2>/dev/null || hostname -I | awk '{print \$1}')

echo "═══════════════════════════════════════════"
echo "  OpenClaw Agent Browser — Connection Test"
echo "═══════════════════════════════════════════"
echo ""

# Test 1: Local CDP
echo -n "1. Local CDP (localhost:\$CDP_PORT)... "
BROWSER_INFO=\$(curl -s http://localhost:\$CDP_PORT/json/version 2>/dev/null)
if [ -n "\$BROWSER_INFO" ]; then
  BROWSER_NAME=\$(echo "\$BROWSER_INFO" | jq -r '.Browser // "unknown"')
  echo "✅ \$BROWSER_NAME"
else
  echo "❌ not running"
  echo "   Run: ~/.openclaw-agent-browser/start-browser.sh"
  exit 1
fi

# Test 2: Remote CDP
echo -n "2. Remote CDP (\$TAILSCALE_IP:\$CDP_PORT)... "
REMOTE=\$(curl -s --connect-timeout 3 http://\$TAILSCALE_IP:\$CDP_PORT/json/version 2>/dev/null)
if [ -n "\$REMOTE" ]; then
  echo "✅ reachable"
else
  echo "❌ not reachable (socat bridge may be down)"
fi

# Test 3: OpenClaw server
echo -n "3. OpenClaw server (\$OPENCLAW_SERVER)... "
if curl -s --connect-timeout 3 http://\$OPENCLAW_SERVER:8008/health &>/dev/null; then
  echo "✅ reachable"
else
  echo "❌ not reachable"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "  CDP Endpoint: http://\$TAILSCALE_IP:\$CDP_PORT"
echo "  OpenClaw config:"
echo "    openclaw browser connect \$TAILSCALE_IP:\$CDP_PORT"
echo "═══════════════════════════════════════════"
TESTER
chmod +x "$INSTALL_DIR/test-connection.sh"

# ── Create systemd service (Linux) ──────────────────────────────────
if [[ "$OS" == "linux" ]]; then
  log "Creating systemd services..."
  mkdir -p "$HOME/.config/systemd/user"

  cat > "$HOME/.config/systemd/user/openclaw-agent-browser.service" << SVCEOF
[Unit]
Description=OpenClaw Agent Browser (CDP)
After=network.target

[Service]
Type=forking
ExecStart=$INSTALL_DIR/start-browser.sh
ExecStop=$INSTALL_DIR/stop-browser.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
SVCEOF

  systemctl --user daemon-reload
  ok "Systemd service created (enable with: systemctl --user enable openclaw-agent-browser)"
fi

# ── Start browser ───────────────────────────────────────────────────
echo ""
read -p "Start browser now? (Y/n): " START_NOW
START_NOW="${START_NOW:-Y}"

if [[ "$START_NOW" =~ ^[Yy] ]]; then
  "$INSTALL_DIR/start-browser.sh"
  sleep 3
  "$INSTALL_DIR/test-connection.sh"
fi

# ── Final output ────────────────────────────────────────────────────
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || hostname -I | awk '{print $1}')
echo ""
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  Installation complete!${NC}"
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BOLD}Browser:${NC}    $BROWSER_NAME"
echo -e "  ${BOLD}CDP Port:${NC}   $CDP_PORT"
echo -e "  ${BOLD}Tailscale:${NC}  $TAILSCALE_IP"
echo -e "  ${BOLD}Endpoint:${NC}   http://$TAILSCALE_IP:$CDP_PORT"
echo ""
echo -e "  ${BOLD}Commands:${NC}"
echo "    Start:  ~/.openclaw-agent-browser/start-browser.sh"
echo "    Stop:   ~/.openclaw-agent-browser/stop-browser.sh"
echo "    Test:   ~/.openclaw-agent-browser/test-connection.sh"
echo ""
echo -e "  ${BOLD}Connect from OpenClaw:${NC}"
echo "    openclaw browser connect $TAILSCALE_IP:$CDP_PORT"
echo ""
echo -e "  ${BOLD}Playwright (JS):${NC}"
echo "    const browser = await chromium.connectOverCDP('http://$TAILSCALE_IP:$CDP_PORT')"
echo ""
