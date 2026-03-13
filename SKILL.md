---
name: agent-browser
description: "Browse and interact with web pages using Vercel agent-browser CLI. AI-optimized snapshots, screenshots, text extraction, and DOM interaction."
metadata:
  openclaw:
    emoji: "🌐"
---

# Agent Browser Skill

Vercel `agent-browser` CLI — AI-optimierte Browser-Steuerung.

## Open a Page (with Snapshot)

```bash
agent-browser open https://example.com
```

Returns an accessibility-tree snapshot with ref IDs for interaction.

## Extract Text

```bash
agent-browser text https://example.com
```

## Take Screenshot

```bash
agent-browser screenshot https://example.com --output /tmp/screenshot.png
```

## DOM Snapshot (AI-optimized)

```bash
agent-browser snapshot https://example.com
```

Returns a compact snapshot using ref-based selectors instead of full CSS/XPath — reduces token usage by ~80%.

## Click an Element

```bash
agent-browser click <ref> https://example.com
```

Where `<ref>` is the reference ID from a previous `open` or `snapshot` call.

## Type into a Field

```bash
agent-browser type <ref> "search text" https://example.com
```

## Use a Specific Browser

```bash
agent-browser open https://example.com --browser brave
agent-browser open https://example.com --browser chrome
agent-browser open https://example.com --browser msedge
```

## Tips for AI Agents

- Use `snapshot` instead of `text` when you need to interact with elements — it returns ref IDs
- Ref IDs are stable within a session — click/type using them
- Screenshots are useful for visual verification
- The `--browser` flag lets you use Brave, Chrome, or Edge instead of built-in Chromium
- Install with `npm install -g agent-browser && agent-browser install`
- Docs: https://agent-browser.dev
