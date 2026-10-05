#!/usr/bin/env bash
#
# Runs the number-agreement fixture against the real providers and grades the
# answers (ADR-072).
#
# A unit test can show that a rule is in the prompt; only this can show whether
# a model follows it. The sentences come from a field report: Swahili marks the
# number of an N-class noun on the verb alone, and Tafsiri was translating
# "Salim gave the cats food" as "gave the cat food" — a plural lost with no
# trace in the output.
#
# Keys come from the environment and are never echoed:
#   read -rs ANTHROPIC_API_KEY && export ANTHROPIC_API_KEY
#   read -rs OPENAI_API_KEY && export OPENAI_API_KEY
#   read -rs MISTRAL_API_KEY && export MISTRAL_API_KEY
#
# Examples:
#   tools/probe_grammar.sh                       # every provider with a key
#   tools/probe_grammar.sh -p claude             # one provider
#   tools/probe_grammar.sh -g both               # with and without the rule
#   tools/probe_grammar.sh -p openai -x '{"reasoning_effort":"low"}'
#   tools/probe_grammar.sh -p claude -m claude-sonnet-4-5
#   tools/probe_grammar.sh -r 3                  # three runs per sentence
#
# Every answer, graded, lands in build/probe/ as a TSV — the summary on screen
# is for reading, that file is for comparing two runs later.
#
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE="$ROOT/tools/grammar_fixture.tsv"
OUT_DIR="$ROOT/build/probe"

PROVIDERS=''
MODEL=''
EXTRA='{}'
RUNS=1
AGREEMENT='on'
LEARN='Swahili'
CONFIDENT='German'

usage() { sed -n '3,28p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while [ $# -gt 0 ]; do
  case "$1" in
    -p|--provider)  PROVIDERS="$2"; shift 2 ;;
    -m|--model)     MODEL="$2"; shift 2 ;;
    -r|--runs)      RUNS="$2"; shift 2 ;;
    -x|--extra)     EXTRA="$2"; shift 2 ;;
    -g|--agreement) AGREEMENT="$2"; shift 2 ;;
    -l|--learn)     LEARN="$2"; shift 2 ;;
    -a|--confident) CONFIDENT="$2"; shift 2 ;;
    -f|--fixture)   FIXTURE="$2"; shift 2 ;;
    -h|--help)      usage 0 ;;
    *) echo "unknown option: $1" >&2; usage 1 ;;
  esac
done

[ -r "$FIXTURE" ] || { echo "no fixture at $FIXTURE" >&2; exit 1; }
case "$AGREEMENT" in on|off|both) ;; *) echo "-g takes on, off or both" >&2; exit 1 ;; esac

[ -n "$PROVIDERS" ] || PROVIDERS='claude openai mistral'
mkdir -p "$OUT_DIR"
RESULTS="$OUT_DIR/grammar-$(date +%Y%m%d-%H%M%S).tsv"
printf 'provider\tmodel\tagreement\trun\tid\tverdict\tsentence\ttranslation\n' > "$RESULTS"

# The translation only. The LANG: header drives the microphone locale rather
# than being part of the text, and NOTES:/EXPLAIN: are commentary — grading
# either would let a correct word in the wrong place pass.
body_of() {
  sed -e '/^LANG:/d' -e '/^MODE:/d' "$1" \
    | sed -n '/^\(NOTES\|EXPLAIN\):[[:space:]]*$/q;p' \
    | sed '/^[[:space:]]*$/d'
}

run_one() { # <provider> <agreement>
  local provider="$1" agreement="$2" model
  case "$provider" in
    claude)  model="${MODEL:-$(sed -n "s/^const _model = '\(.*\)';/\1/p" "$ROOT/lib/core/services/claude_service.dart")}" ;;
    openai)  model="${MODEL:-$(sed -n "s/^const _model = '\(.*\)';/\1/p" "$ROOT/lib/core/services/openai_service.dart")}" ;;
    mistral) model="${MODEL:-$(sed -n "s/^const _model = '\(.*\)';/\1/p" "$ROOT/lib/core/services/mistral_service.dart")}" ;;
    *) echo "unknown provider: $provider" >&2; return 1 ;;
  esac

  echo
  echo "=================================================================="
  echo "$provider | $model | agreement rule $agreement | $RUNS run(s)"
  echo "=================================================================="

  local pass=0 fail=0 err=0
  while IFS=$'\t' read -r id sentence expect forbid note; do
    case "$id" in ''|\#*) continue ;; esac

    for ((run = 1; run <= RUNS; run++)); do
      local raw body verdict
      raw="$(mktemp)"
      "$ROOT/tools/probe_prompt.sh" -p "$provider" -t "$sentence" \
        -l "$LEARN" -a "$CONFIDENT" -n -g "$agreement" \
        ${MODEL:+-m "$MODEL"} -x "$EXTRA" --content-only > "$raw" 2>/dev/null
      body="$(body_of "$raw" | tr '\n' ' ' | sed 's/  */ /g; s/^ //; s/ $//')"
      rm -f "$raw"

      if [ -z "$body" ] || [[ "$body" == NO\ CONTENT* ]]; then
        verdict='ERROR'; err=$((err + 1))
      elif ! grep -qiE "\\b($expect)\\b" <<<"$body"; then
        verdict='FAIL'; fail=$((fail + 1))
      elif [ "$forbid" != '-' ] && grep -qiE "\\b($forbid)\\b" <<<"$body"; then
        verdict='FAIL'; fail=$((fail + 1))
      else
        verdict='pass'; pass=$((pass + 1))
      fi

      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$provider" "$model" "$agreement" "$run" "$id" "$verdict" \
        "$sentence" "$body" >> "$RESULTS"

      if [ "$verdict" = 'pass' ]; then
        printf '  pass  %-11s %s\n' "$id" "$sentence"
      else
        printf '  %-5s %-11s %s\n' "$verdict" "$id" "$sentence"
        printf '        expected %s%s — got: %s\n' \
          "$expect" "$([ "$forbid" != '-' ] && echo " / not $forbid")" "$body"
      fi
    done
  done < "$FIXTURE"

  echo "  ----------------------------------------------------------------"
  echo "  $provider, rule $agreement: $pass passed, $fail failed, $err errored"
}

for provider in ${PROVIDERS//,/ }; do
  case "$AGREEMENT" in
    both) run_one "$provider" off; run_one "$provider" on ;;
    *)    run_one "$provider" "$AGREEMENT" ;;
  esac
done

echo
echo "Every answer: $RESULTS"
