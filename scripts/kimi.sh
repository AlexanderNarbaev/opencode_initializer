#!/usr/bin/env bash
# kimi — direct Moonshot Kimi API via curl
source ~/.config/opencode/secrets.env 2>/dev/null
MODEL="${KIMI_MODEL:-kimi-k3}"
MAX_TOKENS="${KIMI_MAX_TOKENS:-16384}"

if [ $# -eq 0 ]; then echo "Usage: kimi 'question'"; exit 1; fi

curl -s --max-time 300 -X POST "https://api.moonshot.ai/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${MOONSHOT_API_KEY}" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"$*\"}],\"max_tokens\":$MAX_TOKENS,\"temperature\":1}" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); m=d['choices'][0]['message']; r=m.get('reasoning_content',''); c=m['content']; print(f'{r}\n\n{c}' if r else c)"
