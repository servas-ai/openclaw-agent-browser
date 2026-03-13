# Installation — OpenClaw Agent Browser

## Voraussetzungen

- **Tailscale** muss auf dem PC installiert und verbunden sein
- Ein Chromium-basierter Browser (Brave, Chrome, Chromium, Edge oder Arc)

## Installation

### Option 1: One-Liner (empfohlen)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/servas-ai/openclaw-agent-browser/main/install.sh)
```

### Option 2: Manuell

```bash
git clone https://github.com/servas-ai/openclaw-agent-browser.git
cd openclaw-agent-browser
bash install.sh
```

## Was passiert bei der Installation

1. **Browser-Auswahl** — du wählst deinen Browser:
   ```
   [1] Brave        (empfohlen)
   [2] Google Chrome
   [3] Chromium
   [4] Microsoft Edge
   [5] Arc          (nur macOS)
   ```

2. **Tailscale-Check** — prüft ob Tailscale verbunden ist

3. **Abhängigkeiten** — installiert Node.js und socat falls nötig

4. **Browser-Start** — startet den Browser mit CDP Remote Debugging auf Port 9222

5. **Verbindungstest** — testet automatisch:
   - Lokaler CDP-Endpoint (localhost:9222)
   - Remote CDP-Endpoint (Tailscale-IP:9222)
   - OpenClaw Server (100.120.120.120)

6. **Systemd-Service** (Linux) — erstellt einen Auto-Start Service

## Nach der Installation

### Browser starten/stoppen

```bash
~/.openclaw-agent-browser/start-browser.sh    # Starten
~/.openclaw-agent-browser/stop-browser.sh     # Stoppen
~/.openclaw-agent-browser/test-connection.sh   # Verbindung testen
```

### Mit OpenClaw verbinden

```bash
openclaw browser connect <DEINE-TAILSCALE-IP>:9222
```

### Auto-Start aktivieren (Linux)

```bash
systemctl --user enable openclaw-agent-browser
systemctl --user start openclaw-agent-browser
```

## Konfiguration

| Variable | Default | Beschreibung |
|---|---|---|
| `OPENCLAW_SERVER` | `100.120.120.120` | OpenClaw Server IP |
| `CDP_PORT` | `9222` | CDP Debug-Port |
| `INSTALL_DIR` | `~/.openclaw-agent-browser` | Installationsverzeichnis |

Beispiel mit eigenem Port:
```bash
CDP_PORT=9333 bash install.sh
```

## Troubleshooting

### Browser startet nicht
```bash
# Prüfe ob der Browser installiert ist
which brave-browser    # oder: which google-chrome
```

### CDP nicht erreichbar
```bash
# Prüfe ob der Port frei ist
lsof -i :9222

# Starte den Browser manuell
brave-browser --remote-debugging-port=9222 --no-first-run &
```

### OpenClaw Server nicht erreichbar
```bash
# Prüfe Tailscale
tailscale status
ping 100.120.120.120
```
