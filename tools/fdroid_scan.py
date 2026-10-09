#!/usr/bin/env python3
r"""Runs F-Droid's APK scan locally, before anything is submitted (ADR-074).

In June 2026 the official F-Droid inclusion was abandoned because its
`check apk` job rejected six Google Play Core classes that a local build
seemed not to contain. They were there all along — as references. The local
check looked for class *definitions*; F-Droid's scanner reads every type name
anywhere in the dexdump output. This reproduces that scanner so the answer
arrives here, in a minute, instead of after a tag, a submission and a CI run.

Mirrors fdroidserver/scanner.py, get_embedded_classes() and scan_binary():
  * every dex in the APK goes through dexdump;
  * every token matching r'[A-Z]+((?:\w+\/)+\w+)' in the WHOLE output is a
    "class" — method signatures and field types count, not only definitions;
  * tokens are matched against the code_signatures of F-Droid's suss.json.

    tools/fdroid_scan.py build/app/outputs/flutter-apk/app-release.apk
    tools/fdroid_scan.py some.apk --suss path/to/suss.json   # offline

Exit status 0 when nothing non-free is found, 1 otherwise. Needs dexdump from
the Android SDK build-tools, which is the same tool F-Droid runs.
"""
import argparse
import glob
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.request
import zipfile

SUSS_URL = "https://fdroid.gitlab.io/fdroid-suss/suss.json"
CLASS_TOKEN = re.compile(r"[A-Z]+((?:\w+\/)+\w+)")  # verbatim from fdroidserver


def find_dexdump():
    sdk = os.environ.get("ANDROID_HOME") or os.path.expanduser("~/Android/Sdk")
    found = sorted(glob.glob(os.path.join(sdk, "build-tools", "*", "dexdump")))
    if not found:
        sys.exit("dexdump not found — install Android SDK build-tools "
                 "or set ANDROID_HOME")
    return found[-1]


def embedded_classes(apk, dexdump):
    classes = set()
    with tempfile.TemporaryDirectory() as tmp, zipfile.ZipFile(apk) as zf:
        for info in zf.infolist():
            with zf.open(info) as fp:
                if fp.read(3) != b"dex":
                    continue
            zf.extract(info, tmp)
            out = subprocess.run([dexdump, os.path.join(tmp, info.filename)],
                                 capture_output=True, text=True, check=False)
            classes |= set(CLASS_TOKEN.findall(out.stdout))
    return classes


def load_signatures(path):
    if path:
        with open(path, encoding="utf-8") as handle:
            return json.load(handle)["signatures"]
    with urllib.request.urlopen(SUSS_URL, timeout=30) as response:
        return json.load(response)["signatures"]


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("apk")
    parser.add_argument("--suss", help="local suss.json instead of the live one")
    args = parser.parse_args()

    classes = embedded_classes(args.apk, find_dexdump())
    signatures = load_signatures(args.suss)

    found = {}
    for name, sig in signatures.items():
        patterns = sig.get("code_signatures")
        if not patterns:
            continue
        rx = re.compile(r"\s*(" + "|".join(patterns) + r")")
        hits = sorted(c for c in classes if rx.match(c))
        if hits:
            found[name] = hits

    print(f"{len(classes)} class tokens in {os.path.basename(args.apk)}")
    for name, hits in sorted(found.items()):
        print(f"  {name}: {len(hits)}")
        for hit in hits[:6]:
            print(f"      {hit}")
        if len(hits) > 6:
            print(f"      … {len(hits) - 6} more")
    print("RESULT:", "would be rejected" if found else "clean")
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
