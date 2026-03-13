#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# Unit Tests — OpenClaw Agent Browser
# Run: bash test.sh
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

PASSED=0; FAILED=0; TOTAL=0
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'

assert() {
  TOTAL=$((TOTAL + 1))
  local desc="$1"; local cmd="$2"; local expect="$3"
  local result
  result=$(eval "$cmd" 2>&1) || true
  if echo "$result" | grep -qi "$expect"; then
    echo -e "${GREEN}✅ $desc${NC}"
    PASSED=$((PASSED + 1))
  else
    echo -e "${RED}❌ $desc${NC}"
    echo "   Expected: $expect"
    echo "   Got:      $(echo "$result" | head -3)"
    FAILED=$((FAILED + 1))
  fi
}

echo "═══════════════════════════════════════════"
echo "  Agent Browser — Unit Tests"
echo "═══════════════════════════════════════════"
echo ""

# ── 1. Installation Tests ──────────────────────────────────────────
echo "── Installation ──"
assert "Node.js is installed" \
  "node -v" \
  "v"

assert "agent-browser CLI is installed" \
  "which agent-browser" \
  "agent-browser"

assert "agent-browser version" \
  "agent-browser --version" \
  "agent-browser"

# ── 2. Basic Command Tests ─────────────────────────────────────────
echo ""
echo "── Basic Commands ──"
assert "open: loads a page" \
  "agent-browser open https://example.com" \
  "Example Domain"

assert "snapshot: returns accessibility tree" \
  "agent-browser snapshot https://example.com" \
  "heading"

assert "snapshot: contains ref IDs" \
  "agent-browser snapshot https://example.com" \
  "ref="

assert "screenshot: creates PNG file" \
  "agent-browser open https://example.com && agent-browser screenshot --output /tmp/ab-unit-test.png && ls -la /tmp/ab-unit-test.png" \
  "ab-unit-test.png"

# ── 3. CDP Remote Tests ────────────────────────────────────────────
echo ""
echo "── CDP Remote Connection ──"

# Start Chrome with CDP if not already running
CDP_RUNNING=$(curl -s http://localhost:9222/json/version 2>/dev/null | grep -c "Browser" || echo "0")
if [ "$CDP_RUNNING" = "0" ]; then
  # Find chromium
  CHROMIUM=$(find ~/.cache/agent-browser ~/.cache/ms-playwright -name "chrome" -type f 2>/dev/null | head -1)
  if [ -n "$CHROMIUM" ]; then
    $CHROMIUM --headless --no-sandbox --remote-debugging-port=9222 --user-data-dir=/tmp/ab-test-profile &
    sleep 3
  fi
fi

assert "CDP: endpoint responds" \
  "curl -s http://localhost:9222/json/version | jq -r '.Browser'" \
  "Chrome"

assert "CDP: agent-browser connects via --cdp" \
  "agent-browser --cdp 9222 open https://example.com" \
  "Example Domain"

assert "CDP: snapshot via --cdp" \
  "agent-browser --cdp 9222 snapshot" \
  "ref="

# ── 4. Tailscale Tests ─────────────────────────────────────────────
echo ""
echo "── Network / Tailscale ──"

if command -v tailscale &>/dev/null; then
  TSIP=$(tailscale ip -4 2>/dev/null || echo "")
  if [ -n "$TSIP" ]; then
    assert "Tailscale: has IPv4 address" \
      "tailscale ip -4" \
      "."

    assert "Tailscale: CDP reachable via Tailscale IP" \
      "curl -s --connect-timeout 3 http://$TSIP:9222/json/version | jq -r '.Browser'" \
      "Chrome"
  else
    echo -e "${RED}⏭️  Tailscale not connected — skipping network tests${NC}"
  fi
else
  echo -e "${RED}⏭️  Tailscale not installed — skipping network tests${NC}"
fi

# ── Results ─────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════"
echo -e "  Results: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}, $TOTAL total"
echo "═══════════════════════════════════════════"

# Cleanup
rm -f /tmp/ab-unit-test.png

exit $FAILED
