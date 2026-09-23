#!/usr/bin/env bash
# Single LLM caller. Outputs the response text to stdout.
#
# Usage:
#   llm.sh --provider anthropic --model <model> --max-tokens <n> --prompt <text>
#
# Model names follow the aider/litellm "<provider>/<model>" convention
# (e.g. "anthropic/claude-sonnet-4-6"). The leading "<provider>/" prefix is
# stripped automatically for the Anthropic API call.
#
# Supported providers:
#   anthropic  — requires ANTHROPIC_API_KEY env var

set -euo pipefail

PROVIDER="anthropic"
MODEL="anthropic/claude-sonnet-4-6"
MAX_TOKENS=512
PROMPT=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --provider)   PROVIDER="$2";   shift 2 ;;
    --model)      MODEL="$2";      shift 2 ;;
    --max-tokens) MAX_TOKENS="$2"; shift 2 ;;
    --prompt)     PROMPT="$2";     shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

case "$PROVIDER" in
  anthropic)
    API_MODEL="${MODEL#anthropic/}"
    curl -sf https://api.anthropic.com/v1/messages \
      -H "x-api-key: $ANTHROPIC_API_KEY" \
      -H "anthropic-version: 2023-06-01" \
      -H "content-type: application/json" \
      -d "$(jq -n \
        --arg     model      "$API_MODEL" \
        --argjson max_tokens "$MAX_TOKENS" \
        --arg     prompt     "$PROMPT" \
        '{model: $model, max_tokens: $max_tokens, messages: [{role: "user", content: $prompt}]}')" \
      | jq -r '.content[0].text'
    ;;
  *)
    echo "Unsupported provider: $PROVIDER" >&2; exit 1
    ;;
esac
