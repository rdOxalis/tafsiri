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
#   tools/probe_grammar.sh --analysis on         # analyse before translating
#   tools/probe_grammar.sh -i obj-pl,perf-pl     # only these fixture rows
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
ANALYSIS='off'
ONLY=''
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
    --analysis)     ANALYSIS="$2"; shift 2 ;;
    -i|--only)      ONLY=",$2,"; shift 2 ;;
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
printf 'provider\tmodel\tagreement\tanalysis\trun\tid\tverdict\ttok_in\ttok_out\tsentence\ttranslation\n' \
  > "$RESULTS"

# The translation only. The LANG: header drives the microphone locale rather
# than being part of the text, and NOTES:/EXPLAIN: are commentary — grading
# either would let a correct word in the wrong place pass.
body_of() {
  # With --analysis on the answer carries its reasoning before a TRANSLATION:
  # line. Grading that would be worthless: it names the right markers in
  # English while the German below it may still say the wrong thing.
  local src="$1"
  if grep -qE '^TRANSLATION:[[:space:]]*$' "$1"; then
    src="$(mktemp)"
    sed -n '/^TRANSLATION:[[:space:]]*$/,$p' "$1" | sed '1d' > "$src"
  fi
  sed -e '/^LANG:/d' -e '/^MODE:/d' "$src" \
    | sed -n '/^\(NOTES\|EXPLAIN\):[[:space:]]*$/q;p' \
    | sed '/^[[:space:]]*$/d'
}

# A provider without a key would otherwise score twelve failures, because the
# skip notice arrives on stdout where the translation is expected. Check first,
# say so once, and spend no requests.
key_for() { # <provider>
  case "$1" in
    claude)  echo "${ANTHROPIC_API_KEY:-}" ;;
    openai)  echo "${OPENAI_API_KEY:-}" ;;
    mistral) echo "${MISTRAL_API_KEY:-}" ;;
  esac
}

# A pattern is matched case-insensitively unless it is prefixed with "cs:".
# Exactly one row needs the distinction, and it needs it badly: polite "Sie"
# is a correct rendering of a 2nd-person plural, "sie" is the 3rd-person
# reading the row exists to catch, and only case tells them apart.
matches() { # <text> <pattern>
  local text="$1" pattern="$2"
  if [ "${pattern#cs:}" != "$pattern" ]; then
    grep -qE "\\b(${pattern#cs:})\\b" <<<"$text"
  else
    grep -qiE "\\b($pattern)\\b" <<<"$text"
  fi
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
  echo "$provider | $model | agreement $agreement | analysis $ANALYSIS | $RUNS run(s)"
  echo "=================================================================="

  local pass=0 fail=0 errors=0
  while IFS=$'\t' read -r id sentence expect forbid note; do
    case "$id" in ''|\#*) continue ;; esac
    [ -n "$ONLY" ] && [[ "$ONLY" != *",$id,"* ]] && continue

    for ((run = 1; run <= RUNS; run++)); do
      local raw err body verdict tok_in tok_out
      raw="$(mktemp)"; err="$(mktemp)"
      "$ROOT/tools/probe_prompt.sh" -p "$provider" -t "$sentence" \
        -l "$LEARN" -a "$CONFIDENT" -n -g "$agreement" --analysis "$ANALYSIS" \
        ${MODEL:+-m "$MODEL"} -x "$EXTRA" --content-only > "$raw" 2>"$err"
      body="$(body_of "$raw" | tr '\n' ' ' | sed 's/  */ /g; s/^ //; s/ $//')"
      # The counts arrive on stderr under --content-only. They are what the
      # cost side of any model decision rests on, so they go in the file.
      tok_in=$(sed -n 's/^--- tokens: \([0-9?]*\) in.*/\1/p' "$err" | head -1)
      tok_out=$(sed -n 's/.*\/ \([0-9?]*\) out$/\1/p' "$err" | head -1)
      rm -f "$raw" "$err"

      if [ -z "$body" ] || [[ "$body" == NO\ CONTENT* ]] \
         || [[ "$body" == \(skipped* ]]; then
        verdict='ERROR'; errors=$((errors + 1))
      elif ! matches "$body" "$expect"; then
        verdict='FAIL'; fail=$((fail + 1))
      elif [ "$forbid" != '-' ] && matches "$body" "$forbid"; then
        verdict='FAIL'; fail=$((fail + 1))
      else
        verdict='pass'; pass=$((pass + 1))
      fi

      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$provider" "$model" "$agreement" "$ANALYSIS" "$run" "$id" "$verdict" \
        "${tok_in:-?}" "${tok_out:-?}" "$sentence" "$body" >> "$RESULTS"

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
  echo "  $provider, rule $agreement, analysis $ANALYSIS: $pass passed, $fail failed, $errors errored"
  echo "  tokens, mean per request: $(awk -F'\t' -v m="$model" -v a="$agreement" -v an="$ANALYSIS" \
    '$2==m && $3==a && $4==an && $8!="?" {i+=$8; o+=$9; n++} END {if (n) printf "%d in / %d out", i/n, o/n; else print "not recorded"}' "$RESULTS")"
}

ran=0
for provider in ${PROVIDERS//,/ }; do
  if [ -z "$(key_for "$provider")" ]; then
    echo
    echo "$provider: skipped — no key in the environment."
    case "$provider" in
      claude)  echo "  read -rs ANTHROPIC_API_KEY && export ANTHROPIC_API_KEY" ;;
      openai)  echo "  read -rs OPENAI_API_KEY && export OPENAI_API_KEY" ;;
      mistral) echo "  read -rs MISTRAL_API_KEY && export MISTRAL_API_KEY" ;;
    esac
    continue
  fi
  ran=1
  case "$AGREEMENT" in
    both) run_one "$provider" off; run_one "$provider" on ;;
    *)    run_one "$provider" "$AGREEMENT" ;;
  esac
done

if [ "$ran" = 0 ]; then
  rm -f "$RESULTS"
  echo
  echo "Nothing ran — no keys. Export at least one of the three above."
  exit 1
fi

echo
echo "Every answer: $RESULTS"
