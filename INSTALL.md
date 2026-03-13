# Agent Browser — KI-Installationsanleitung

> **Tool:** Vercel `agent-browser` CLI (https://agent-browser.dev)
> **Ziel:** agent-browser auf diesem PC installieren, Browser starten, Verbindung zum OpenClaw-Server (100.120.120.120) testen

## Schritt 1: Node.js prüfen

```bash
node -v  # Muss >= 18 sein
# Falls nicht vorhanden:
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
```

## Schritt 2: agent-browser installieren

```bash
npm install -g agent-browser
agent-browser install   # Lädt Chromium herunter
```

## Schritt 3: Testen

```bash
# Seite öffnen
agent-browser open https://example.com

# Text extrahieren
agent-browser text https://example.com

# Screenshot
agent-browser screenshot https://example.com --output /tmp/test.png

# DOM Snapshot (für AI — reduziert Token-Verbrauch)
agent-browser snapshot https://example.com
```

## Schritt 4: Mit anderem Browser (optional)

```bash
# Brave
agent-browser open https://example.com --browser brave

# Chrome
agent-browser open https://example.com --browser chrome

# Edge
agent-browser open https://example.com --browser msedge
```

## Schritt 5: Tailscale + OpenClaw Verbindung

```bash
# Tailscale IP
tailscale ip -4

# OpenClaw erreichbar?
curl -s http://100.120.120.120:8008/health
# Erwartung: "OK"
```

## Schritt 6: Ergebnis melden

```
✅ agent-browser installiert
   Version:     [agent-browser --version]
   Tailscale:   [TAILSCALE_IP]
   OpenClaw:    erreichbar / nicht erreichbar
   Test:        Screenshot erstellt unter /tmp/test.png
```

## Verfügbare Befehle

| Befehl | Beschreibung |
|---|---|
| `agent-browser open <URL>` | Seite öffnen, Snapshot zurückgeben |
| `agent-browser text <URL>` | Sichtbaren Text extrahieren |
| `agent-browser screenshot <URL>` | Screenshot als PNG |
| `agent-browser snapshot <URL>` | DOM Snapshot (AI-optimiert) |
| `agent-browser click <ref> <URL>` | Element per Ref-ID klicken |
| `agent-browser type <ref> <text> <URL>` | Text in Feld eingeben |
| `agent-browser install` | Chromium herunterladen |
