#!/usr/bin/env bash
#
# Fires the app's real prompt at a provider's API, without building the app.
#
# Prompt-level behaviour cannot be settled by a test — a test can show that a
# rule is in the prompt, never that a model obeys it. Before this existed the
# only way to find out was to build, install, type a sentence and look, which
# takes long enough that one tends to guess instead. ADR-070 and ADR-071 were
# both settled with this in an afternoon, and both turned up something the
# guess had wrong.
#
# Keys come from the environment and are never echoed:
#   read -rs OPENAI_API_KEY && export OPENAI_API_KEY      # ChatGPT
#   read -rs MISTRAL_API_KEY && export MISTRAL_API_KEY    # Mistral
#   read -rs ANTHROPIC_API_KEY && export ANTHROPIC_API_KEY # Claude
#
# Examples:
#   tools/probe_prompt.sh                          # every provider with a key
#   tools/probe_prompt.sh -p openai -r 3           # ChatGPT, three runs
#   tools/probe_prompt.sh -p mistral -t "Ich habe Hunger"
#   tools/probe_prompt.sh -p openai -m gpt-4o-mini # try another model
#   tools/probe_prompt.sh -c                       # the correction prompt
#   tools/probe_prompt.sh -p openai -x '{"reasoning_effort":"low"}'
#   tools/probe_prompt.sh -g off                   # without the agreement rule
#   tools/probe_prompt.sh --content-only           # just the model's answer
#
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

LEARN='Swahili'
CONFIDENT='German'
TEXT='die Sprache ist schwer zu lernen'
MODE='translate'
EXPLAIN='on'
PROVIDERS=''
MODEL=''
RUNS=1
EXTRA='{}'
RAW=0
AGREEMENT='on'
CONTENT_ONLY=0

usage() { sed -n '3,26p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while [ $# -gt 0 ]; do
  case "$1" in
    -p|--provider)  PROVIDERS="$2"; shift 2 ;;
    -m|--model)     MODEL="$2"; shift 2 ;;
    -t|--text)      TEXT="$2"; shift 2 ;;
    -l|--learn)     LEARN="$2"; shift 2 ;;
    -a|--confident) CONFIDENT="$2"; shift 2 ;;
    -r|--runs)      RUNS="$2"; shift 2 ;;
    -x|--extra)     EXTRA="$2"; shift 2 ;;
    -c|--correction) MODE='correct'; shift ;;
    -n|--no-explanations) EXPLAIN='off'; shift ;;
    --raw)          RAW=1; shift ;;
    -g|--agreement) AGREEMENT="$2"; shift 2 ;;
    --content-only) CONTENT_ONLY=1; shift ;;
    -h|--help)      usage 0 ;;
    *) echo "unknown option: $1" >&2; usage 1 ;;
  esac
done

for tool in jq curl dart; do
  command -v "$tool" >/dev/null || { echo "missing: $tool" >&2; exit 1; }
done
echo "$EXTRA" | jq -e . >/dev/null 2>&1 || { echo "--extra is not valid JSON: $EXTRA" >&2; exit 1; }

# The prompt comes from the app's own code, so the probe cannot drift away
# from what ships. Same for the model: it is read out of the service file
# rather than repeated here, and only -m overrides it.
PROMPT="$(cd "$ROOT" && dart run tools/dump_prompt.dart \
            "$LEARN" "$CONFIDENT" "$MODE" "$EXPLAIN" "$TEXT" "$AGREEMENT")" || exit 1

model_of() { # <service file>
  sed -n "s/^const _model = '\(.*\)';/\1/p" "$ROOT/lib/core/services/$1"
}

# Bodies mirror lib/core/services/*_service.dart. They differ in more than the
# model name: Claude takes the system prompt as its own field, and every GPT-5
# model rejects 'max_tokens' and requires 'max_completion_tokens' (ADR-071).
probe() { # <provider> <model> <run>
  local provider="$1" model="$2" run="$3" url key_header body out content

  case "$provider" in
    openai)
      [ -n "${OPENAI_API_KEY:-}" ] || return 2
      url='https://api.openai.com/v1/chat/completions'
      key_header="Authorization: Bearer $OPENAI_API_KEY"
      body=$(jq -cn --arg m "$model" --argjson p "$PROMPT" --argjson x "$EXTRA" \
        '{model:$m, max_completion_tokens:4096,
          messages:[{role:"system",content:$p.system},
                    {role:"user",content:$p.user}]} + $x') ;;
    mistral)
      [ -n "${MISTRAL_API_KEY:-}" ] || return 2
      url='https://api.mistral.ai/v1/chat/completions'
      key_header="Authorization: Bearer $MISTRAL_API_KEY"
      body=$(jq -cn --arg m "$model" --argjson p "$PROMPT" --argjson x "$EXTRA" \
        '{model:$m, max_tokens:4096,
          messages:[{role:"system",content:$p.system},
                    {role:"user",content:$p.user}]} + $x') ;;
    claude)
      [ -n "${ANTHROPIC_API_KEY:-}" ] || return 2
      url='https://api.anthropic.com/v1/messages'
      key_header="x-api-key: $ANTHROPIC_API_KEY"
      body=$(jq -cn --arg m "$model" --argjson p "$PROMPT" --argjson x "$EXTRA" \
        '{model:$m, max_tokens:4096, system:$p.system,
          messages:[{role:"user",content:$p.user}]} + $x') ;;
    *) echo "unknown provider: $provider" >&2; return 1 ;;
  esac

  out=$(curl -s "$url" -H "$key_header" -H 'content-type: application/json' \
        -H 'anthropic-version: 2023-06-01' -d "$body")

  if [ "$CONTENT_ONLY" = 0 ]; then
    echo "=================================================================="
    echo "$provider | $model | $MODE | explanations $EXPLAIN | agreement $AGREEMENT | run $run"
    echo "------------------------------------------------------------------"
  fi
  if [ "$RAW" = 1 ]; then echo "$out" | jq .; return 0; fi

  # OpenAI and Mistral answer in .choices[0].message.content, Claude in
  # .content[0].text. Anything else is an error worth showing verbatim.
  content=$(echo "$out" | jq -r '.choices[0].message.content // .content[0].text // empty')
  if [ -n "$content" ]; then
    echo "$content"
    # Counts go to stderr under --content-only, so a caller can grade stdout
    # without stripping anything off the end.
    local tokens="--- tokens: $(echo "$out" | jq -r '.usage.prompt_tokens // .usage.input_tokens // "?"') in / $(echo "$out" | jq -r '.usage.completion_tokens // .usage.output_tokens // "?"') out"
    if [ "$CONTENT_ONLY" = 1 ]; then echo "$tokens" >&2; else echo "$tokens"; fi
  else
    echo "NO CONTENT — response was:"
    echo "$out" | jq . 2>/dev/null || echo "$out"
  fi
}

[ -n "$PROVIDERS" ] || PROVIDERS='openai mistral claude'
any=0
for provider in ${PROVIDERS//,/ }; do
  case "$provider" in
    openai)  default_model=$(model_of openai_service.dart) ;;
    mistral) default_model=$(model_of mistral_service.dart) ;;
    claude)  default_model=$(model_of claude_service.dart) ;;
    *) echo "unknown provider: $provider" >&2; exit 1 ;;
  esac
  for ((i = 1; i <= RUNS; i++)); do
    probe "$provider" "${MODEL:-$default_model}" "$i"
    case $? in
      2) echo "(skipped $provider — no key in the environment)"; break ;;
      1) exit 1 ;;
    esac
    any=1
  done
done

[ "$any" = 1 ] || { echo; echo "Nothing ran. Export at least one key first:"; echo "  read -rs OPENAI_API_KEY && export OPENAI_API_KEY"; exit 1; }
