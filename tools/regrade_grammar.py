#!/usr/bin/env python3
"""Re-grades saved probe runs against the current fixture.

The answers are in the TSV; only the verdict is an opinion about them. When a
grading rule turns out to be wrong — and two of them were — this recovers the
corrected numbers from runs already paid for, instead of spending the requests
again. It never calls an API.

    tools/regrade_grammar.py                     # every run in build/probe
    tools/regrade_grammar.py build/probe/x.tsv   # one of them
    tools/regrade_grammar.py --selftest          # check the rules themselves
"""
import csv
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def load_fixture(path):
    rules = {}
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            if line.startswith("#") or not line.strip():
                continue
            id_, _sentence, expect, forbid, *_ = line.rstrip("\n").split("\t")
            rules[id_] = (expect, forbid)
    return rules


def matches(text, pattern):
    """Case-insensitive unless the pattern is prefixed with "cs:"."""
    flags = 0 if pattern.startswith("cs:") else re.IGNORECASE
    body = pattern[3:] if pattern.startswith("cs:") else pattern
    return re.search(rf"\b(?:{body})\b", text, flags) is not None


def grade(text, expect, forbid):
    if not text or text.startswith("NO CONTENT") or text.startswith("(skipped"):
        return "ERROR"
    if not matches(text, expect):
        return "FAIL"
    if forbid != "-" and matches(text, forbid):
        return "FAIL"
    return "pass"


# One right and one wrong answer per fixture row. The wrong ones are what the
# providers actually produced, which is what makes this worth keeping: a rule
# that accepts the right answer is easy, a rule that also rejects the observed
# error is the one worth having. Two of these caught rules that were wrong.
SAMPLES = {
    "obj-sg": ("Salim gab der Katze Futter.", "Salim gab den Katzen Futter."),
    "obj-pl": ("Salim gab den Katzen Futter.", "Salim gab der Katze Futter."),
    "perf-pl": ("Salim hat ihnen schon Futter gegeben.",
                "Salim hat der Katze bereits das Futter gegeben."),
    "perf-pl-pa": ("Salim hat den Katzen Futter gegeben.",
                   "Salim hat der Katze Futter gegeben."),
    "subj-sg": ("Der Hund schläft.", "Die Hunde schlafen."),
    "subj-pl": ("Die Hunde schlafen.", "Der Hund schläft."),
    "obj-sg-mw": ("Ich sah die Freundin.", "Ich sah die Freunde."),
    "obj-pl-wa": ("Ich sah die Freunde.", "Ich sah den Freund / die Freundin."),
    "adj-sg": ("Die kleine Katze schläft.", "Die kleinen Katzen schlafen."),
    "adj-pl": ("Die kleinen Katzen schlafen.", "Die kleine Katze schläft."),
    "wa-2pl": ("Ich habe euch/Sie beim Spazierengehen gefunden",
               "Ich fand sie gehend."),
    "wa-3pl": ("Ich traf sie beim Spazierengehen an.",
               "Ich traf euch beim Spazierengehen an."),
}


def selftest(rules):
    bad = 0
    for id_, (expect, forbid) in rules.items():
        right, wrong = SAMPLES.get(id_, (None, None))
        if right is None:
            print(f"  {id_:<12} no sample — rule unverified")
            bad += 1
            continue
        got_right = grade(right, expect, forbid)
        got_wrong = grade(wrong, expect, forbid)
        ok = got_right == "pass" and got_wrong == "FAIL"
        bad += not ok
        print(f"  {id_:<12} correct:{got_right:<5} observed-error:{got_wrong:<5}"
              f"  {'ok' if ok else 'BROKEN'}")
    print()
    print("every rule separates the right answer from the observed error"
          if not bad else f"{bad} rule(s) do not")
    return 1 if bad else 0


def main(argv):
    if "--selftest" in argv:
        return selftest(load_fixture(ROOT / "tools" / "grammar_fixture.tsv"))
    rules = load_fixture(ROOT / "tools" / "grammar_fixture.tsv")
    files = [Path(a) for a in argv[1:]] or sorted(
        (ROOT / "build" / "probe").glob("grammar-*.tsv"))
    if not files:
        print("no runs found in build/probe")
        return 1

    for path in files:
        rows = list(csv.DictReader(path.open(encoding="utf-8"), delimiter="\t"))
        if not rows:
            continue
        arms = defaultdict(lambda: [0, 0, 0])  # pass, total, changed
        rows_failing = defaultdict(lambda: defaultdict(lambda: [0, 0]))
        for row in rows:
            id_ = row["id"]
            if id_ not in rules:
                continue
            expect, forbid = rules[id_]
            now = grade(row["translation"], expect, forbid)
            arm = (row["model"], row.get("agreement", "?"),
                   row.get("analysis", "-"))
            arms[arm][0] += now == "pass"
            arms[arm][1] += 1
            arms[arm][2] += now != row["verdict"]
            cell = rows_failing[arm][id_]
            cell[0] += now == "pass"
            cell[1] += 1

        print(f"\n{path.name}")
        for arm, (passed, total, changed) in sorted(arms.items()):
            model, agreement, analysis = arm
            note = f"  ({changed} verdict(s) changed)" if changed else ""
            print(f"  {model:<20} rule={agreement:<4} analysis={analysis:<4} "
                  f"{passed:>3}/{total}{note}")
            for id_, (p, n) in sorted(rows_failing[arm].items()):
                if p < n:
                    print(f"      {id_:<12} {p}/{n}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
