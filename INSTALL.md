# Agent Browser — KI-Installationsanleitung

> **Zielgruppe:** KI-Agent auf einem Tailscale-verbundenen Rechner
> **Ziel:** Browser mit CDP starten, socat-Bridge einrichten, und Verbindung zum OpenClaw-Server (100.120.120.120) herstellen

## Schritt 1: System prüfen

```bash
# OS erkennen
uname -s  # Linux oder Darwin

# Tailscale prüfen
tailscale ip -4  # Muss eine IP zurückgeben

# Browser finden — teste in dieser Reihenfolge:
which brave-browser || which google-chrome || which chromium-browser || which chromium || which microsoft-edge
# macOS: ls "/Applications/Brave Browser.app" || ls "/Applications/Google Chrome.app"
```

**Abbruch falls:** Tailscale nicht installiert oder kein Browser gefunden.

## Schritt 2: Abhängigkeiten

```bash
# Node.js (falls nicht vorhanden)
node -v || (curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt-get install -y nodejs)

# socat (Linux, für Remote-Zugriff)
which socat || sudo apt-get install -y socat
```

## Schritt 3: Browser mit CDP starten

Ersetze `BROWSER` mit dem gefundenen Browser-Befehl aus Schritt 1.

```bash
mkdir -p ~/.openclaw-agent-browser

# Browser starten
BROWSER --remote-debugging-port=9222 --no-first-run --no-default-browser-check --user-data-dir=~/.openclaw-agent-browser/profile &

# Warten bis CDP bereit ist (max 15s)
for i in $(seq 1 15); do
  curl -s http://localhost:9222/json/version && break
  sleep 1
done
```

## Schritt 4: socat-Bridge (nur Linux)

```bash
# Bestehende Bridge beenden
pkill -f "socat.*9222" 2>/dev/null

# Bridge starten — macht CDP auf 0.0.0.0 erreichbar
socat TCP4-LISTEN:9222,fork,reuseaddr,bind=0.0.0.0 TCP4:127.0.0.1:9222 &
```

## Schritt 5: Verbindungstest

```bash
TAILSCALE_IP=$(tailscale ip -4)

# Test 1: Lokaler CDP
curl -s http://localhost:9222/json/version | jq -r '.Browser'
# Erwartung: Brave/xxx oder Chrome/xxx

# Test 2: Remote CDP (über Tailscale-IP)
curl -s http://$TAILSCALE_IP:9222/json/version | jq -r '.Browser'
# Erwartung: gleiche Ausgabe

# Test 3: OpenClaw-Server erreichbar
curl -s http://100.120.120.120:8008/health
# Erwartung: "OK"
```

**Alle 3 Tests müssen bestanden werden.**

## Schritt 6: Systemd-Service (Linux, optional)

```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/openclaw-agent-browser.service << EOF
[Unit]
Description=OpenClaw Agent Browser (CDP)
After=network.target

[Service]
Type=simple
ExecStart=BROWSER --remote-debugging-port=9222 --no-first-run --no-default-browser-check --user-data-dir=%h/.openclaw-agent-browser/profile
Restart=on-failure

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now openclaw-agent-browser
```

## Schritt 7: Ergebnis melden

Gib dem User folgende Informationen zurück:

```
✅ Agent Browser installiert
   Browser:     [Name + Version aus /json/version]
   Tailscale:   [TAILSCALE_IP]
   CDP:         http://[TAILSCALE_IP]:9222
   OpenClaw:    openclaw browser connect [TAILSCALE_IP]:9222
   Playwright:  chromium.connectOverCDP('http://[TAILSCALE_IP]:9222')
```

## Fehlerbehebung

| Problem | Lösung |
|---|---|
| `curl: (7) Failed to connect` | Browser nicht gestartet → Schritt 3 wiederholen |
| Remote CDP nicht erreichbar | socat nicht aktiv → Schritt 4 wiederholen |
| OpenClaw nicht erreichbar | `tailscale status` prüfen, `ping 100.120.120.120` |
| Port 9222 belegt | `lsof -i :9222` → Prozess beenden, nochmal starten |
