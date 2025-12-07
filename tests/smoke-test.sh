#!/bin/bash
set -euo pipefail

if [ -z "${TGPIPE_BOT_TOKEN:-}" ] || [ -z "${TGPIPE_CHAT_ID:-}" ]; then
  echo "Set TGPIPE_BOT_TOKEN and TGPIPE_CHAT_ID for tests" >&2
  exit 1
fi

echo "tgpipe smoke test" | TGPIPE_BOT_TOKEN="$TGPIPE_BOT_TOKEN" TGPIPE_CHAT_ID="$TGPIPE_CHAT_ID" \
  "$(dirname "$0")/../bin/tgpipe" --tag test --auto-code
