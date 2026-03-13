# Agent Browser — Installationsanleitung für Remote-PC (macOS/Linux)

> **Ziel:** `agent-browser` auf diesem PC installieren, Browser mit CDP starten,
> damit OpenClaw (100.120.120.120) diesen Browser über Tailscale fernsteuern kann.

---

## Voraussetzungen

- **Tailscale** installiert und verbunden (gleites Netzwerk wie der OpenClaw-Server)
- **Node.js** >= 18

---

## Schritt 1: agent-browser installieren

```bash
npm install -g agent-browser
agent-browser install
```

Prüfen:
```bash
agent-browser --version   # Sollte >= 0.19.0 sein
agent-browser open https://example.com   # Muss "Example Domain" zurückgeben
```

## Schritt 2: Browser-Auswahl

Standardmäßig nutzt agent-browser das eingebaute Chromium. Du kannst auch Brave, Chrome oder Edge verwenden:

```bash
# Chromium (Standard, kein --browser nötig)
agent-browser open https://example.com

# Brave
agent-browser --browser brave open https://example.com

# Chrome
agent-browser --browser chrome open https://example.com

# Edge
agent-browser --browser msedge open https://example.com
```

## Schritt 3: Browser mit CDP starten (für Remote-Zugriff)

Damit OpenClaw vom Server aus auf den Browser zugreifen kann, muss Chrome mit CDP (Chrome DevTools Protocol) gestartet werden:

### macOS — Brave:
```bash
"/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" \
  --remote-debugging-port=9222 \
  --no-first-run \
  --user-data-dir=$HOME/.openclaw-agent-browser/profile &
```

### macOS — Chrome:
```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --remote-debugging-port=9222 \
  --no-first-run \
  --user-data-dir=$HOME/.openclaw-agent-browser/profile &
```

### Linux — Brave:
```bash
brave-browser \
  --remote-debugging-port=9222 \
  --no-first-run \
  --no-sandbox \
  --user-data-dir=$HOME/.openclaw-agent-browser/profile &
```

### Linux — Chrome:
```bash
google-chrome \
  --remote-debugging-port=9222 \
  --no-first-run \
  --no-sandbox \
  --user-data-dir=$HOME/.openclaw-agent-browser/profile &
```

### Verifizieren:
```bash
curl -s http://localhost:9222/json/version | jq '.Browser'
# Erwartung: "Brave/xxx" oder "Chrome/xxx"
```

## Schritt 4: socat-Bridge (nur Linux)

Auf Linux bindet Chrome CDP an `127.0.0.1`. Damit der OpenClaw-Server via Tailscale zugreifen kann, braucht man socat:

```bash
sudo apt-get install -y socat
socat TCP4-LISTEN:9222,fork,reuseaddr,bind=0.0.0.0 TCP4:127.0.0.1:9222 &
```

> **macOS:** Nicht nötig! Chrome bindet auf macOS an `0.0.0.0`.

## Schritt 5: Verbindungstest

```bash
# Eigene Tailscale IP herausfinden
TSIP=$(tailscale ip -4)
echo "Meine Tailscale IP: $TSIP"

# Test 1: Lokaler CDP
curl -s http://localhost:9222/json/version | jq '.Browser'
# ✅ Muss Browser-Version zurückgeben

# Test 2: CDP über Tailscale
curl -s http://$TSIP:9222/json/version | jq '.Browser'
# ✅ Muss gleiche Version zurückgeben

# Test 3: agent-browser über CDP
agent-browser --cdp 9222 open https://example.com
# ✅ Muss "Example Domain" zurückgeben

# Test 4: OpenClaw-Server erreichbar
curl -s http://100.120.120.120:8008/health
# ✅ Muss "OK" zurückgeben
```

## Schritt 6: OpenClaw verbinden

Auf dem **OpenClaw-Server** (100.120.120.120) kann jetzt der Browser gesteuert werden:

```bash
# Ersetze <DEINE-TAILSCALE-IP> mit der IP aus Schritt 5
agent-browser --cdp <DEINE-TAILSCALE-IP>:9222 open https://example.com
agent-browser --cdp <DEINE-TAILSCALE-IP>:9222 snapshot
agent-browser --cdp <DEINE-TAILSCALE-IP>:9222 screenshot --output /tmp/remote.png
```

### Oder per Playwright (JavaScript):
```javascript
const { chromium } = require('playwright');
const browser = await chromium.connectOverCDP('http://<DEINE-TAILSCALE-IP>:9222');
const page = browser.contexts()[0].pages()[0];
await page.goto('https://example.com');
console.log(await page.title());
```

## Schritt 7: Auto-Start (optional)

### macOS — LaunchAgent:
```bash
mkdir -p ~/Library/LaunchAgents
cat > ~/Library/LaunchAgents/com.openclaw.agent-browser.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.openclaw.agent-browser</string>
  <key>ProgramArguments</key>
  <array>
    <string>/Applications/Brave Browser.app/Contents/MacOS/Brave Browser</string>
    <string>--remote-debugging-port=9222</string>
    <string>--no-first-run</string>
    <string>--user-data-dir=/Users/YOUR_USERNAME/.openclaw-agent-browser/profile</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
</dict>
</plist>
EOF
launchctl load ~/Library/LaunchAgents/com.openclaw.agent-browser.plist
```

### Linux — systemd:
```bash
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/openclaw-agent-browser.service << EOF
[Unit]
Description=OpenClaw Agent Browser (CDP)
After=network.target

[Service]
Type=simple
ExecStart=brave-browser --remote-debugging-port=9222 --no-first-run --no-sandbox --user-data-dir=%h/.openclaw-agent-browser/profile
Restart=on-failure

[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload
systemctl --user enable --now openclaw-agent-browser
```

---

## Zusammenfassung

```
MacBook (dein PC)                    Server (OpenClaw)
┌─────────────────┐                 ┌─────────────────┐
│  Brave/Chrome    │  ◄── CDP ───►  │  agent-browser   │
│  :9222           │   Tailscale    │  --cdp IP:9222   │
│  agent-browser   │                │  openclaw        │
└─────────────────┘                 └─────────────────┘
```

| Komponente | Wert |
|---|---|
| CDP Port | 9222 |
| OpenClaw Server | 100.120.120.120 |
| Tailscale IP | `tailscale ip -4` |
| Verbindungsbefehl | `agent-browser --cdp <TSIP>:9222 open <URL>` |
