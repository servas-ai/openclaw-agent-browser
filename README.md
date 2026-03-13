# OpenClaw Agent Browser

Remote browser control for OpenClaw using [Vercel agent-browser](https://agent-browser.dev) CLI.

## Quick Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/servas-ai/openclaw-agent-browser/main/install.sh)
```

## Manual Install

```bash
npm install -g agent-browser
agent-browser install
```

## Usage

```bash
agent-browser open <URL>                    # Open + snapshot
agent-browser text <URL>                    # Extract text
agent-browser screenshot <URL> -o out.png   # Screenshot
agent-browser click <ref> <URL>             # Click element
agent-browser type <ref> "text" <URL>       # Type in field
```

## With Brave / Chrome

```bash
agent-browser open https://example.com --browser brave
```

## Docs

https://agent-browser.dev

## License

MIT © servas-ai
