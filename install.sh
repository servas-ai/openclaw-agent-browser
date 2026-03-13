#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  OpenClaw + Vercel Agent Browser — Installer                   ║
# ║  Installiert agent-browser CLI und verbindet mit OpenClaw      ║
# ╚══════════════════════════════════════════════════════════════════╝
set -euo pipefail

OPENCLAW_SERVER="${OPENCLAW_SERVER:-100.120.120.120}"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

echo -e "${BOLD}${BLUE}"
echo "╔══════════════════════════════════════════════════╗"
echo "║  OpenClaw + Agent Browser Installer  v2.0       ║"
echo "║  Powered by Vercel agent-browser CLI            ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── 1. Node.js prüfen ──────────────────────────────────────────────
echo -n "1. Node.js... "
if command -v node &>/dev/null; then
  echo -e "${GREEN}$(node -v)${NC}"
else
  echo -e "${YELLOW}nicht gefunden, installiere...${NC}"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install node
  else
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
  fi
  echo -e "${GREEN}$(node -v) installiert${NC}"
fi

# ── 2. agent-browser installieren ───────────────────────────────────
echo -n "2. agent-browser CLI... "
if command -v agent-browser &>/dev/null; then
  echo -e "${GREEN}bereits installiert${NC}"
else
  echo -e "${YELLOW}installiere...${NC}"
  npm install -g agent-browser
  echo -e "${GREEN}installiert${NC}"
fi

# ── 3. Chromium herunterladen ───────────────────────────────────────
echo -n "3. Chromium Browser... "
agent-browser install 2>&1 | tail -1
echo -e "${GREEN}bereit${NC}"

# ── 4. Browser-Auswahl ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}Welchen Browser möchtest du verwenden?${NC}"
echo ""
echo "  [1] Chromium (agent-browser built-in) — empfohlen"
echo "  [2] Brave"
echo "  [3] Google Chrome"
echo "  [4] Microsoft Edge"
echo ""
read -p "Auswahl (1-4, default=1): " CHOICE
CHOICE="${CHOICE:-1}"

BROWSER_ARG=""
case $CHOICE in
  2) BROWSER_ARG="--browser brave" ;;
  3) BROWSER_ARG="--browser chrome" ;;
  4) BROWSER_ARG="--browser msedge" ;;
  *) BROWSER_ARG="" ;; # default chromium
esac

# ── 5. Tailscale prüfen ────────────────────────────────────────────
echo ""
echo -n "4. Tailscale... "
if command -v tailscale &>/dev/null; then
  TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "nicht verbunden")
  echo -e "${GREEN}$TAILSCALE_IP${NC}"
else
  TAILSCALE_IP="localhost"
  echo -e "${YELLOW}nicht installiert (nur lokal nutzbar)${NC}"
fi

# ── 6. Test ─────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}5. Test — öffne example.com...${NC}"
agent-browser open https://example.com $BROWSER_ARG 2>&1 | head -5
echo ""
echo -e "${BOLD}6. Screenshot-Test...${NC}"
agent-browser screenshot https://example.com --output /tmp/agent-browser-test.png $BROWSER_ARG 2>&1 | head -3
if [ -f /tmp/agent-browser-test.png ]; then
  echo -e "${GREEN}✅ Screenshot erstellt: /tmp/agent-browser-test.png${NC}"
else
  echo -e "${YELLOW}⚠️  Screenshot konnte nicht erstellt werden${NC}"
fi

# ── 7. OpenClaw-Verbindung testen ───────────────────────────────────
echo ""
echo -n "7. OpenClaw Server ($OPENCLAW_SERVER)... "
if curl -s --connect-timeout 3 "http://$OPENCLAW_SERVER:8008/health" &>/dev/null; then
  echo -e "${GREEN}erreichbar ✅${NC}"
else
  echo -e "${YELLOW}nicht erreichbar (Tailscale prüfen)${NC}"
fi

# ── Fertig ──────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  ✅ Installation abgeschlossen!${NC}"
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BOLD}Befehle:${NC}"
echo "    agent-browser open <URL>             # Seite öffnen"
echo "    agent-browser text <URL>             # Text extrahieren"
echo "    agent-browser screenshot <URL>       # Screenshot"
echo "    agent-browser snapshot <URL>         # DOM Snapshot"
echo "    agent-browser click <ref> <URL>      # Element klicken"
echo "    agent-browser type <ref> <text> <URL> # Text eingeben"
echo ""
echo -e "  ${BOLD}Tailscale IP:${NC} $TAILSCALE_IP"
echo -e "  ${BOLD}Docs:${NC} https://agent-browser.dev"
echo ""
