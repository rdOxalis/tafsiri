# Architecture Decision Records

## ADR-046: Read subprocess output as UTF-8, not as the system encoding
**Date:** 2026-08-14
**Status:** Accepted
**Context:** With ADR-045 in place the Windows log finally read `448 B out, text=37 chars, confidence=96.0` and `OK: 37 chars` — recognition working, high confidence, correct length. What appeared in the input field was `ÐœÐ¾Ð»Ñ Ñ‚Ðµ, Ð´Ð°Ð¹ Ð¼Ð¸ Ð¼Ð°ÑÐ»Ð¾Ñ‚Ð¾`: the UTF-8 bytes of `Моля те, дай ми маслото` with every byte rendered as its own Latin character. `Process.run` decodes with `systemEncoding` by default, which is UTF-8 on Linux and the machine's **ANSI code page** on Windows; Tesseract always writes UTF-8. So each two-byte Cyrillic character arrived as two characters, which is why the count was 37 rather than 24. Nothing failed anywhere: exit code 0, 96 confidence, a plausible-looking string. This is the same shape as the `tsv` config file (ADR-043) and the mis-attributed error (ADR-045) — the failure mode this component keeps producing is *silent success with wrong content*, and it is the one that survives longest because every check it passes is real.
**Decision:** Read both streams as UTF-8 explicitly, with `allowMalformed: true` so a damaged byte costs one replacement character rather than an exception — a mangled letter is worth reporting to the user, a crash is not. This is also more correct on Linux, where a `LANG=C` session would have had the same problem for the same reason. Only the default runner changes; the injectable `ProcessRunner` used by the tests is untouched.
**Consequences:** Cyrillic, Greek and Arabic reads return the characters Tesseract actually found, on every platform. The existing integration test already covers this — it asserts the result matches `[Ѐ-ӿ]`, which mojibake does not — but only on a machine where the bug reproduces, so it passed on Linux throughout. That is the limitation worth naming: a test that can only fail on the platform you do not develop on is documentation, not a guard. The diagnostic log (ADR-044) is what actually closed this one, and it closed it in a single round after four rounds of guessing without it.

---

## ADR-045: A poor read is a poor read, not a missing package
**Date:** 2026-08-14
**Status:** Accepted
**Context:** The diagnostic log from ADR-044 answered the Windows question on its first run, in one line: `8453 B out, text=2287 chars, confidence=42.1`, followed by `languageMissing: no trained data for script-cyrl`. Recognition had **worked**. Tesseract loaded the Cyrillic script data — installed, found, used — read 2287 characters, and the result was thrown away for scoring 42.1 against the gate of 60. The app then reported the one thing that was certainly not true: that the trained data was missing. The user had spent four rounds installing and reinstalling a package that was never absent. The underlying situation is worth recording too, because it is the ordinary case on a desktop: the image was a full-window screenshot, mostly Latin interface with a little Cyrillic in it. OSD called it Cyrillic at **1.76** — barely over the noise floor of 1.0, against ~4.5 for a genuinely Cyrillic page — so the app loaded Cyrillic data *only* and read a Latin interface with it. The configured languages, which would have read that screenshot well, never got a turn: the script branch threw before reaching them.
**Decision:** Separate the two failures the branch had conflated. Trained data that is genuinely absent (`scriptArgument` resolves to nothing) still throws `OcrLanguageMissingException` and names the package — that hint is correct and actionable. But when the data *was* found and used and the read still came out poor, fall through to the configured languages and let them try. If they do better, that is the answer; if they do no better, the existing ladder reports a failed read with the measured confidence. What is never said again is "install what you are already looking at".
**Consequences:** A screenshot whose script OSD misjudges now recovers instead of dead-ending, which is the common desktop case and was previously unreachable. The cost is one extra recognition run on that path, after a run that was already wasted. The `1.76` measurement argues that `kMinScriptConfidence = 1.0` is too permissive, but tuning a magic number is a worse fix than making the flow survive a wrong answer, so the threshold stands and the flow now tolerates it. Two tests pin the split: a poor script read with a good configured read returns the configured text, and a poor script read with no better alternative raises `OcrFailedException` rather than an install hint. The general shape of this bug is the one this whole series keeps producing — **an error message that names a cause the code never actually checked** — and it stayed alive for four rounds because the message was confident, specific, and wrong.

---

## ADR-044: OCR writes a diagnostic log to a file, because desktop cannot print
**Date:** 2026-08-14
**Status:** Accepted
**Context:** Four rounds of Windows debugging produced four hypotheses, three code fixes, four rebuilds by the person reporting the bug — and the same message every time. Each fix was a real defect (ADR-043), yet none was demonstrably *the* defect, because the app could not be asked what it was doing. The `[OCR]` lines existed but went through `debugPrint`, and a Flutter **release** build on Windows is a GUI subsystem application: Dart binds its standard output at startup, when no console is attached, and the runner attaching to the parent console afterwards does not reconnect it. Running the installed app from a terminal printed nothing at all. So the one platform that was broken was the one platform that could not report. The debugging that finally worked was manual — running `tesseract` by hand in PowerShell and reading the output — which proved the engine innocent but said nothing about the caller.
**Decision:** `ocrLog` writes every OCR step to `<system temp>/tafsiri-ocr.log`, and to `debugPrint` as before. It records what a diagnosis actually needs: the image path, the installed language list as parsed, the `-l` argument and any missing codes, the detected script and its confidence, the resolved script-data name (or `NOTHING INSTALLED`), the exact argument list of every run, exit codes with stderr, and for each result the raw byte count against the parsed text length — that last pair being the tell that separates "Tesseract read nothing" from "we failed to parse what it returned". Writes are best-effort and swallow every error: a diagnostic that can break recognition is worse than no diagnostic. The file truncates past 64 KB so it stays pasteable and the run being investigated is never buried.
**Consequences:** A Windows user can now answer "what did it do" with one file instead of a rebuild. The cost is a log file appearing in temp during normal use, which is the usual trade and why it is capped rather than rotated. The wider lesson is the one this session paid four rounds for: **when a platform is unreachable, make it reachable before making it correct.** Guessing scales badly across a build-and-report loop that costs the other person ten minutes each time, and three of the four hypotheses were plausible enough to be worth fixing but not one of them was verifiable from here. The instrumentation should have come first.

---


## ADR-043: Ask Tesseract for TSV by parameter, not by config file name
**Date:** 2026-08-14
**Status:** Accepted
**Context:** OCR turned out to work on Windows after all — the service shells out to a bare `tesseract`, and `CreateProcess` resolves that against `PATH` and appends `.exe`, so an installed Tesseract is simply found. With the engine and the Cyrillic script data both installed and the current build running (`1.0.11+11 · 451ed76`, checked in Settings), recognition still reported the script package as missing. The cause is a hidden dependency in how the run was invoked. `_recognise` passed `tsv` as a trailing argument, which is not a flag but the name of a **config file** that lives in the installation's `tessdata/configs/`. Where that file is absent, Tesseract does not fail: it writes `read_params_file: Can't open tsv` to stderr, **exits 0**, and prints ordinary text instead of TSV. `parseTesseractTsv` then finds no word rows, the read counts as unusable, and the caller falls through to the branch that names trained data to install — telling the user to install something that was already there. Every recognition on that machine had been failing this way; only script *detection* worked, because `--psm 0` needs no config file. Reproduced locally by pointing `TESSDATA_PREFIX` at a tessdata directory with `configs/` removed, which is exactly the earlier confusion in this same session where a hand-built tessdata directory produced "no word rows" until `configs/` was copied in.
**A second, independent cause behind the first.** With the TSV fix built and running, the same message came back. `--list-langs` on Windows reports the entry as `script\Cyrillic` — the platform's path separator — while `scriptArgument` compared literally against `script/Cyrillic` and `Cyrillic`. Neither matched, so the run was skipped entirely and installed data was reported as missing, with the user looking at a `tessdata\script` folder that plainly contained it. Matching is now separator-blind, and the value handed back is the spelling the installation itself used: Tesseract is given its own words back rather than ours, which also avoids assuming it accepts a foreign separator. Two bugs, one symptom, and the first fix could not reveal the second because both end in the same branch — a reminder that "still broken after the fix" is not evidence the fix was wrong.

**And a third, which was the one that mattered.** Still the same message. `parseTesseractTsv` split its input on `'\n'`, and Tesseract on Windows ends every line with CRLF — so the header's last field was named `text\r`, `header.indexOf('text')` returned -1, the guard reported an empty page, and the caller read that as "nothing recognised, so the trained data must be missing". This one did not only affect Cyrillic: **every recognition on Windows had been failing this way**, which is why nothing there had ever worked. The trailing `\r` on the *word* cells hid the cause, because those are trimmed individually and looked fine. Proven by removing the fix and watching the CRLF test go from `Моля те,` to `''`.

Three causes, one message, discovered strictly in order because each hid the next: the separator mismatch skipped the run, so the parser was never reached; the parser then emptied the page, so the confidence gate was never reached. Only the first of the three — the `tsv` config file — is unconfirmed on the affected machine; it is kept because it removes a real dependency on what an installation happens to ship, and because its failure mode is the same silent exit-0-with-wrong-output.

**Decision:** Ask for the same output as a parameter: `-c tessedit_create_tsv=1` instead of the trailing `tsv`. Split TSV on `\r?\n`. Byte-identical output, no dependency on what the installation happens to ship in `configs/`. A unit test pins the argument shape — both that `-c tessedit_create_tsv=1` is present and that a bare `tsv` is not — because the failure it guards against is silent and would otherwise only surface as a wrong error message on someone else's machine.
**Consequences:** Image-to-text works on Windows with a user-installed Tesseract, which the documentation had been claiming was impossible; that claim needs correcting in `build_windows.ps1`, `docs/todo.md` and the v1.0.11 release notes. Bundling the engine (still open) is now clearly worth doing rather than speculative, since the only missing piece is shipping the files. One related wart remains: `tesseractPackageHint` returns Debian package names on Linux and bare codes elsewhere, so a Windows user is told to install `script-cyrl` — a name that means nothing there. The general lesson is worth keeping: a dependency that degrades to *plausible wrong output with exit code 0* is worse than one that fails, and this is the second time in this ADR series that a silent success has been the actual bug.

---

## ADR-042: Releases are assembled by hand; the GitHub Actions workflow is removed
**Date:** 2026-08-14
**Status:** Accepted — supersedes ADR-036
**Context:** ADR-036 added `.github/workflows/release.yml`, which built all three artefacts on a `v*` tag and attached them to the release. It was never asked for, and the owner of the project said so when it first became relevant — while preparing 1.0.11, the first release since the workflow was written. It had also never run: it triggers only on a `v*` tag, and the newest tag at the time (`v1.0.10`, 2026-08-12) predated the workflow's own commit `79d2112` (2026-08-14). So there was no evidence it worked, and its first act would have been to take over a release that was already being assembled by hand — building Linux and Windows itself and overwriting assets with `gh release upload --clobber`, including the Windows installer that was going to be uploaded manually. Automation that nobody ordered, has never run, and races with the person doing the work is not an asset.
**Decision:** Delete the workflow. Releases are built and uploaded by hand: `flutter build apk --release` and `flutter build linux --release` on the Linux machine, `.\build_windows.ps1` on Windows, then `gh release create` / `gh release upload`. Both build scripts already inject the commit stamp, so a hand-made artefact is as identifiable as a generated one (ADR-041). ADR-036 stays in this file, marked superseded, rather than being erased — the record that it existed and why it went is the useful part.
**Consequences:** A release is three manual builds plus an upload, on two machines. That is the honest cost, and it is what was happening anyway. The APK keeps being signed locally with the real upload key from `android/key.properties`, which also settles the question ADR-036 left open — whether to put the signing keystore into GitHub Actions secrets. It does not go anywhere; the todo item asking about it is closed as "not needed". Nothing else in the repo referenced the workflow. If CI is ever wanted, this decision is not an argument against it — only against introducing it unbidden and untested on the day of a release.

---

## ADR-041: The build stamp is the commit, and nothing else
**Date:** 2026-08-14
**Status:** Accepted
**Context:** The stamp shown under Settings (ADR-036 era) carried a `-dirty` suffix whenever tracked files differed from HEAD. The intent was honest — say when a binary does not correspond to a commit — but it does not survive contact with Flutter. `flutter pub get` regenerates `linux/flutter/generated_plugin_registrant.*`, `windows/flutter/generated_plugin_registrant.*`, `generated_plugins.cmake` and `macos/Flutter/GeneratedPluginRegistrant.swift` from the plugin list on **every** run, and `build_windows.ps1` calls it immediately before taking the stamp. The build therefore dirtied its own tree and then labelled itself after the mess. Reported from the first Windows build: a release binary would have shown `1.0.11+11 · 7ea9cce-dirty` because of eight files nobody had edited. On Linux the same marker was stuck on for a different reason — `android/build/reports/problems/problems-report.html`, a Gradle report that is tracked by accident. A version string that is always wrong tells you nothing, and shipping one to users is worse than not marking it at all.
**Decision:** `build_stamp` / `Get-BuildStamp` return the short commit and nothing else. The dirt check is not deleted, it is **moved to the one place that needs it**: `install.sh` reuses an existing bundle only when the recorded commit matches *and* the tree is clean, which is what ADR-037-era commit `d963681` added it for — an uncommitted change leaves the commit unchanged, so without this the stamps would match while the source had moved on. That check lives in a new `tree_is_dirty`, and it excludes the generated registrants by pathspec, because counting files the build itself writes would force a rebuild on every single run. `build_windows.ps1` gets no such helper: it always builds, so it never had a reuse decision to make.
**Consequences:** Settings shows `1.0.11+11 · 7ea9cce`, which is what anyone reading it actually wanted — the commit to check out. What is lost is a genuine signal: a build made from a tree with real uncommitted edits is now indistinguishable from a clean one. That is an accepted trade, because the signal was pinned on for unrelated reasons and had stopped carrying information. `install.sh` still refuses to reuse such a bundle, so the failure mode that motivated the marker — debugging behaviour that is not in the code any more — stays covered on the platform where bundles are reused. Left open and worth doing: `android/build/reports/problems/problems-report.html` should be untracked and `android/build/` ignored; it is a build artefact under version control and the reason every Linux tree reads as dirty.

---

## ADR-040: Ctrl+V accepts an image, without losing Ctrl+V for text
**Date:** 2026-08-14  
**Status:** Accepted  
**Context:** A screenshot is the fastest way to get foreign text into a translator, and until now it took four steps: save the image, open the source sheet, pick the file, wait. Flutter's `Clipboard` is text-only, so an image sitting on the clipboard is invisible to the framework — `Clipboard.getData(kTextPlain)` returns null and the app concludes there is nothing to paste. The obvious dependency, `super_clipboard`, brings a Rust toolchain into the build, which would land on the F-Droid recipe and both desktop builds for one feature; that trade is clearly wrong here. The constraint that shapes the rest: whatever handles Ctrl+V takes it away from the `TextField`, whose own paste then no longer runs. Getting images in at the cost of ordinary text pasting would be a bad bargain.  
**Decision:** A `ClipboardImageService` interface with a Linux implementation that shells out to `wl-paste`, falling back to `xclip` — the same reasoning as Tesseract (ADR-037): no native build step, nothing to bundle, and the tools are already present on a desktop that has a clipboard manager. Wayland is asked **first**: on a Wayland session the X11 bridge frequently carries the text flavour of a copy but not the image, so asking `xclip` first reports "no image" while the picture sits there — measured on this machine, where `xclip -t TARGETS` listed only `UTF8_STRING` while `wl-paste --list-types` offered `image/png`. PNG is preferred over the other flavours; the bytes go to a temporary file, because both OCR engines take a path and the desktop one is a separate process that could not be handed a buffer. Ctrl+V (and Cmd+V) is bound in `InputArea`, wrapping the field that will have focus, and the handler is **image-first, text-second**: `pasteImageFromClipboard()` returns false when there was no image, and the same keystroke then pastes text — reproduced by hand at the cursor, replacing the selection, because the field's own paste no longer runs. The action bar's paste button gets the same order, so the feature exists without a keyboard. Platforms with no implementation return "no image", which is precisely the path they took before this existed.  
**Consequences:** Paste a screenshot, get its text. Linux only for now: Android needs a platform channel into `ClipboardManager`, and Windows has no OCR engine bundled yet anyway (ADR-037), so an image pasted there would have nothing to read it — both are noted in the todo rather than guessed at. Twelve new tests (153 total, was 141). Two of them are worth their weight. **A live check against the real clipboard caught a bug the unit tests could not**: `Process.run`'s `stdoutEncoding` is nullable *and* null is the value meaning "raw bytes", so a runner typed `{Encoding? stdoutEncoding}` silently ran the **type listing** in binary mode too — the parser then matched `image/png` against the text of a byte array and every clipboard looked empty. The fakes returned a String either way and were happy. The parameter is now a `bool binary`, which has no such default, and the fake asserts the mode per call so it can never again be more forgiving than `Process.run`. The second: `testWidgets` bodies run in a fake-async zone where real file I/O never completes, so the test covering the image path hangs rather than fails unless the interaction is wrapped in `runAsync` — the same trap as the platform override in ADR-039, and worth knowing before the next test touches the file system.

---

## ADR-039: Settings say what they decide, and offer only what the platform can do
**Date:** 2026-08-14  
**Status:** Accepted  
**Context:** Four small things that each cost a user something. (1) The microphone sat in the action bar on Linux, permanently greyed out, because `speech_to_text` has no Linux implementation (ADR-031) — a disabled control reads as "not right now" and sends people looking for the setting that enables it, of which there is none. (2) and (4) Both language pickers listed their entries in the order the languages had been added to the app over time — `English (UK), Kiswahili, Deutsch, Français, …` — which is meaningful to whoever added them and to nobody else; with twelve entries you scan the whole list every time. (3) `Primärsprache` and `Sekundärsprache` are the two settings that decide the entire translation logic (which way a text is turned, what correction mode corrects into), and their names do not say which is which. A user who guesses wrong gets an app that translates the wrong way with no error to explain it.  
**Decision:** Platform capability moves into `lib/core/platform_capabilities.dart` — `isMobilePlatform`, `hasCamera` (moved out of the OCR factory, where it was a lodger) and the new `hasSpeechInput` — and the microphone is now wrapped in `if (hasSpeechInput)` rather than merely disabled. The distinction is deliberate: where an engine exists the button stays *disabled* when a permission is denied, because that is something the user can go and change; where none exists it is *absent*, because nothing they do will help. **`hasSpeechInput` is therefore "not Linux", not "is mobile"** — a correction caught while preparing the first Windows build. `speech_to_text` declares Android, iOS, web, macOS *and* Windows (the last via the endorsed `speech_to_text_windows`, in beta); Linux is the only target with nothing behind it. Keying the check on `isMobilePlatform` would have silently removed voice input from Windows and macOS, which is precisely the kind of thing a capability flag named after a form factor invites. Both pickers sort through one shared `compareLanguageLabels`, which folds case and Latin diacritics so `Español` files under E rather than after `Svenska`, and ranks scripts explicitly so `Български` groups at the end because that is useful, not because its code points happen to land there. `String.compareTo` alone gets both of those wrong. The names stay **endonyms**: you recognise `Deutsch` faster than `German`, whatever the UI language, and translating them would have cost 144 ARB entries to make the list harder to use for the people most likely to need it. `Auto` in the speech picker is pinned to the top rather than sorted — it is a mode, not a language, and its label is localised, so sorting it would move it per UI language. Both language fields get an `info_outline` button in their `suffixIcon` opening a dialog, with the same text as the hover tooltip so desktop users need no click; the OK button reuses `MaterialLocalizations`, which is already translated everywhere, instead of adding a thirteenth string in thirteen files.  
**Consequences:** Two new ARB keys × 13 files (`app_en.arb` exists alongside `app_en_GB.arb`), translated rather than left in English — the German wording is the user's own, the other twelve follow it. The explanation deliberately repeats the field name (`Primärsprache – die Sprache, …`) because the tooltip is shown without the dialog title around it. Eight new tests (141 total, was 133): the ordering rules including the diacritic and non-Latin cases that a naive sort gets wrong, and the microphone's presence pinned on both a mobile and a desktop `TargetPlatform`. The platform override in those widget tests has to be cleared inside the test body, not in `addTearDown` — the framework asserts all foundation debug variables are unset the moment the body returns. `hasCamera` moving files is the one behaviour-free change here; `ocr_service_factory.dart` keeps only the provider.

---

## ADR-038: Tile the page so OSD will judge it, and never trust a confident read in an unreadable script
**Date:** 2026-08-14  
**Status:** Accepted  
**Context:** ADR-037 closed with a limit it had measured but not solved: `tesseract --psm 0` refuses to name a script when the page holds too few characters, so script detection "improves the outcome but does not guarantee it". That limit turned out to be the *normal* case, not an edge one. Reported against the build from `d963681` — so with every ADR-037 fix already in it — a photograph of `Моля те, дай ми маслото.` came back as `Mona Te, nal Mu MacnoTo.`, exactly the failure ADR-037 was written to prevent. Reproduced on the command line: OSD answers those 21 characters with "Too few characters. Skipping this page", `detectScript` returns `null`, the front guard never runs, and English trained data reads the Cyrillic at **70.6** mean confidence — ten points past the gate, so `_isUsable` accepts it and returns it as a successful read. Two things made this invisible. The suite already had a test named "never returns Latin nonsense for a Cyrillic image", but its fixtures are 40 and 94 characters and clear OSD's floor on their own; only a short phrase can reach the broken path. And the `configured.missing` check that produces the "install `tesseract-ocr-bul`" message sat on the *failure* branch, below the early return — so precisely when the read was confidently wrong, it was never consulted. Raising resolution does not help: the floor counts characters, not pixels (tested at 2×, 3× and 4×, all still "Too few characters"). A short phrase off a menu, a sign or a phrasebook is what this app is *for*, so leaving it unhandled was not an acceptable limit.  
**Decision:** Two independent guards, because they fail in different ways. **First, give OSD the characters it wants.** When `--psm 0` returns nothing usable, the page is repeated in a 3×3 grid onto a white background and asked once more. Repetition invents no glyph the page did not already carry, so the verdict stays honest — it only lifts the character count over the floor. Measured on the reported image: "Too few characters" becomes `Script: Cyrillic` at 26.7 confidence, well past the 1.0 noise threshold, and the existing ADR-037 front guard then does its job. The tiling uses the `image` package, already present transitively and now declared directly; a page that cannot be decoded simply yields `null` as before. **Second, stop treating confidence as evidence of the right alphabet.** A configured language whose trained data is missing *and* whose script nothing loaded can read now blocks the early return: if OSD could not name the script and such a language exists, the result is refused with `OcrLanguageMissingException` no matter how confident it was. Missing *Latin* languages are deliberately exempt — English reads those letters and only drops diacritics, which the model restores downstream, so refusing there would be a false alarm. The install hint also got more precise: when a configured-but-missing language is written in the detected script, it names that language (`tesseract-ocr-bul`, ~2 MB) instead of the whole script pack (`tesseract-ocr-script-cyrl`, ~28 MB), falling back to the script pack only when the image turned out to be a script the user never configured.  
**Third, take the script's `-l` name from `--list-langs` instead of assuming a layout** (added after installing the package it advises). With detection fixed, the message finally appeared — and installing `tesseract-ocr-script-cyrl` changed nothing, because the argument was hardcoded as `script/Cyrillic`. Upstream `tessdata` does ship the file under `script/`, and Tesseract resolves that argument straight to that path, but **Debian installs the same data flat** as `/usr/share/tesseract-ocr/5/tessdata/Cyrillic.traineddata`. The run then fails with "Error opening data file", which `_recognise` cannot distinguish from a missing package — so an *installed* package still produced "install tesseract-ocr-script-cyrl", a dead end that no user action could clear. `scriptArgument` now picks whichever of `script/Cyrillic` and `Cyrillic` `--list-langs` actually reports, and skips the run entirely when neither is there. This is also the general lesson for the packaging work still open on Windows: the trained-data layout is a property of the installation, never of the engine.

**Consequences:** The reported image now works end to end. Worth recording *whose* trained data it needed, because the first diagnosis got it wrong: the reporter translates Swahili↔German and merely *photographs* Bulgarian, so Bulgarian is configured nowhere and `tesseract-ocr-bul` would never have entered the `-l` argument. Nothing here has to recognise Bulgarian — OCR only has to get the characters right, and the AI identifies the language downstream anyway. The script package is therefore not a fallback but the correct answer for this whole class of use, which is the ADR-037 premise restated: you photograph what you cannot read, so the image decides, not the settings. Measured on that image: `eng+deu` 70.6 confidence and wrong, `Cyrillic` 96.2 and exact. The second guard is deliberately conservative: with a non-Latin language configured and OSD still inconclusive after tiling, a genuinely Latin photograph is refused with an install hint rather than returned. That is the intended direction — ADR-037's whole argument is that silent, fluent invention downstream is worse than a visible "could not read that" — and tiling makes the ambiguous branch rare enough that the trade is cheap. Cost is one extra Tesseract run and one temporary PNG on the short-text path only; the temp directory is deleted in a `finally`. Tests: eight new (133 total, was 125), including `ocr_sample_bulgarian_short.png` — the actual failing image — driven against the real binary, a unit test that pins the false-alarm case (French missing, English loaded) so the Latin exemption cannot be tightened away by accident, and one that fixes the flat Debian layout in place. The integration tests now take the happy path on this machine rather than the exception branch, since `tesseract-ocr-script-cyrl` is installed.

---

## ADR-037: Image-to-text on desktop via Tesseract, behind an engine interface
**Date:** 2026-08-14  
**Status:** Accepted  
**Context:** OCR was the one feature the desktop builds could not do: `google_mlkit_text_recognition` is Android/iOS only, so picking an image worked (the file dialog opens) while recognition always failed (ADR-031, ADR-035). Two ways out. The first was to send the image to the AI provider that is already configured — all three models in use take images, no new dependency, one API call instead of two steps, and it would have worked on every platform at once. The second was a local engine. The deciding argument came from the use pattern rather than from the engines: the extracted text is handed to a language model *anyway*, and models repair OCR damage in context extremely well ("Tafadhal1 nlpe s1agi" comes back correct), so the accuracy a local engine has to reach is far lower than it would be if the text went straight to the user. That tips the balance, and two further properties settle it — Tesseract is Apache-2.0, so unlike the proprietary ML Kit blob it does not block an official F-Droid build (ADR-028, ADR-030), and it keeps the promise README and the privacy policy make, that images never leave the device. The vision route would have cost that promise.  
**Decision:** Introduce `OcrService` (`lib/core/services/ocr/`) with two implementations: `MlKitOcrService` for Android/iOS and `TesseractOcrService` for desktop, chosen by `ocrServiceProvider` on `defaultTargetPlatform`. The controller no longer knows which engine it has. Tesseract runs as a **subprocess**, not through FFI — no native build step, no plugin, and the engine can be upgraded independently. One invocation with the `tsv` config yields text and per-word confidence together; `parseTesseractTsv` rebuilds line structure from the `block/par/line` columns, addressing columns by header name because the column set has changed between Tesseract versions. **A mean confidence below 60 is treated as a failure.** This gate is the reason the design is safe: handed garble, the language model downstream does not fail — it writes fluent, plausible text that was never on the image, and the user cannot tell. A visible "could not read that" is the honest outcome. The `-l` argument comes from the two languages the user already configured for translation, passed together (`swa+eng`) so mixed-language pages work — exactly the case correction mode is built for (ADR-033); a name→ISO 639-2 map accepts English names, native spellings and two-letter codes, uninstalled trained data is dropped, and English is the last resort. A missing binary is `OcrUnavailableException` and gets its own message ("install Tesseract") rather than the generic OCR error, because retrying cannot fix it. The camera entry in the image source sheet is hidden on desktop, where it was a guaranteed dead end.  
**Consequences:** Image-to-text works on Linux. It needs `tesseract-ocr` plus the trained data for the languages in use (`tesseract-ocr-swa`, …); `install.sh` warns when either is missing, in the same shape as the existing `libsqlite3` check. **Windows is not done** — the engine has to be bundled into the installer, and unlike SQLite there is no tidy official zip with a published hash to fetch, so that is real packaging work. 16 unit tests cover the TSV parsing, the confidence gate and the language selection against a fake process; one integration test drives the real binary against `test/fixtures/ocr_sample.png` and skips itself where Tesseract is absent, so it can never be the only guard. Quality caveat: Tesseract is excellent on flat, high-contrast scans and much weaker on angled, curved or badly lit phone photos, and no preprocessing (deskew, threshold) is done yet — that is the obvious next quality lever. Android is untouched and keeps ML Kit, which stays free, offline and token-free there; but it now sits behind an interface, so replacing it later is a second implementation rather than surgery on the controller. Two new localised strings in every ARB file.

**Which trained data actually matters** (measured with only `eng` installed): Swahili — plain ASCII Latin, no diacritics — comes back *perfect* from English trained data, so the app's primary language needs no package at all. German and Polish keep their letters but lose their diacritics (`Käse`→`Kase`, `masła`→`masia`) at ~90 confidence, which passes the gate and is exactly the damage the AI repairs downstream. Cyrillic reads as noise at 39 confidence and is rejected. So the practical rule is: `tesseract-ocr` alone covers Latin scripts adequately; language packages improve them; **foreign scripts genuinely require their own trained data**. That is why the low-confidence path distinguishes the two causes — when the read is rejected *and* a configured language had no trained data, the message names the package to install (`tesseract-ocr-bul`) instead of blaming the image. A missing package that still produced good text stays silent, because for Latin scripts it is not worth a warning.

**Script detection runs first, not as a rescue** (revised the same day, after a failed test). Deriving the OCR language from the configured *target* languages is backwards: a translation app is used on text one cannot read, so the script in the image may be one the user never configured — primary German, secondary English, photograph a Bulgarian sign. Both language fields are deliberately free text as well (the AI accepts any spelling in any script), so the name→code lookup can miss for reasons that have nothing to do with the image.

The first attempt at this ran script detection only *after* the confidence gate rejected a read, on the assumption that a wrong alphabet always produces low confidence. **That assumption is wrong, and a real test caught it.** Cyrillic is full of Latin lookalikes — М о н а Т е с р — so English trained data reads a Bulgarian page as `Mons, Haute Mu MacnoTo` at 60.5 mean confidence, one and a half points past the threshold. It sailed through the gate and would have reached the model, which then invents something fluent from it. The lesson generalises: **confidence measures whether the glyphs were legible, never whether they were the right alphabet.** Those are different failures and need different guards.

So detection moved to the front: `tesseract --psm 0` reports the script using `osd.traineddata`, which ships with the engine and costs 0.09 s against 0.07 s for the recognition itself — nothing next to the API call that follows. If no configured language is written in the detected script, recognition runs with Tesseract's **script-level** trained data (`script/Cyrillic`, one package per script covering every language written in it), and only when that is not installed does the user get told what to install (`tesseract-ocr-script-cyrl`). Latin is exempt from the advice: it is already covered by any Latin language we might load, so a failure there is a bad photograph and a package hint would misdirect. Detections below a script confidence of 1.0 are ignored as noise; the scale is small and not comparable to word confidence (a clean Cyrillic page measures ~4.5, a Latin one ~25).

This also demotes the free-text problem from an outright failure to a loss of accuracy — within one script, loading `eng` instead of `deu` costs diacritics, which the model restores. **Limit:** OSD needs enough characters. Measured, two lines are detected and a two-word sign returns "Too few characters", falling back to the configured languages and the plain message. It improves the outcome; it does not guarantee it. *(This limit turned out to be the normal case for a translation app, not an edge one, and is resolved in **ADR-038**.)*

---

## ADR-036: One tag builds and publishes all three release artefacts
**Date:** 2026-08-14  
**Status:** Superseded by ADR-042 — the workflow was removed before it ever ran  
**Context:** With Windows (ADR-035) there are now three artefacts per release, and until now every one of them was built locally and uploaded by hand — the `Release` workflow only ran `flutter build apk --release` and threw the result away. That does not scale to three platforms, and hand-assembly is where mislabelled or forgotten assets come from. Two details constrain the automation. First, `android/app/build.gradle.kts` falls back to the **debug** signing config when `android/key.properties` is absent, which it always is on a runner: an APK built in CI without the release keystore would be signed with a throwaway key, could not be installed over an existing Tafsiri, and would look legitimate. Silently publishing that is worse than publishing nothing. Second, the existing releases carry hand-written titles and notes ("Tafsiri v1.0.10 — Backup and restore"), so a workflow that creates releases from a template would overwrite editorial work.  
**Decision:** Five jobs. `version` compares the tag against `pubspec.yaml` and fails the whole run on a mismatch, then hands the version to the others so all asset names come from one source. `android`, `linux` and `windows` build and upload their artefact, named `tafsiri-<version>[.apk|-linux-x64.tar.gz|-windows-x64.exe]` — the Windows installer was renamed from `TafsiriSetup-<version>.exe` to fit that convention before the first Windows release went out. `publish` downloads them and runs `gh release upload --clobber`, creating a bare release only if the tag does not have one yet, so a hand-written release keeps its title and notes. The APK is built **only** when `ANDROID_KEYSTORE_BASE64` is set; without it the job emits a warning and produces nothing. The `android` job is `continue-on-error`, and `publish` requires only `linux` and `windows` to have succeeded — a broken Android toolchain must not hold back the other two platforms.  
**Consequences:** A release becomes `git tag vX.Y.Z && git push --tags`, plus writing the notes. For the APK to be part of that, four secrets have to exist: `ANDROID_KEYSTORE_BASE64` (the keystore, base64-encoded), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` — i.e. the upload key lives in GitHub Actions secrets, which is a deliberate trust decision and the reason the APK is opt-in rather than required. Until those exist, releases ship Linux and Windows automatically and the APK stays a manual `gh release upload`, exactly as before. The Linux tarball reproduces the layout of the 1.0.10 asset (one top-level `tafsiri-<version>-linux-x64/` directory). Re-running the workflow on the same tag replaces the assets rather than erroring. The Android job in CI is unproven — the local build needed Java 17 and NDK 27 (see todo) — which is precisely why it cannot block the others.

---

## ADR-001: Flutter Android-first
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** App needed for Android devices. Cross-platform capability (iOS) is desirable later but not required for v1.  
**Decision:** Flutter with Android as primary target. iOS support deferred to v2.  
**Consequences:** Single codebase ready for future iOS extension with minimal rework.

---

## ADR-002: Riverpod for state management
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** App has multiple independent state domains: active translation, history list, settings, loading/error states.  
**Decision:** Use `riverpod` / `flutter_riverpod`. Provides compile-safe providers, clean separation of controllers and UI, and good testability.  
**Consequences:** Slightly higher initial setup cost vs. `setState`, but pays off for this complexity level.

---

## ADR-003: Language detection via AI prompt, not local library
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** The primary target language is Swahili. Local language detection libraries (e.g. `langdetect`) have poor coverage for Swahili and similar languages.  
**Decision:** Language detection is performed by the selected AI provider as part of the translation prompt. The prompt asks the model to detect and conditionally translate in one call.  
**Consequences:** One fewer dependency. Slightly higher latency vs. local detection, but saves a second API round-trip. Result quality depends on the AI provider.

---

## ADR-004: sqflite for local history storage
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** Translation history and favourites need to persist across app restarts. Needs to be queryable (filter by favourite, sort by date).  
**Decision:** `sqflite` with a single `translation_entry` table. Simple schema, well-supported on Android.  
**Consequences:** No external server required. Data stays on device. No built-in sync (out of scope for v1).

---

## ADR-005: google_mlkit_text_recognition for OCR
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** Image input requires OCR to extract text. Options: cloud OCR (extra API cost/latency) vs. on-device.  
**Decision:** `google_mlkit_text_recognition` runs on-device, no additional API key or network call needed.  
**Consequences:** Works offline for the OCR step. Model download may be required on first use on some devices.

---

## ADR-006: ARB-based localisation for 10 languages
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** App must support Swahili, German, British English, French, Dutch, Spanish, Danish, Norwegian, Swedish, Polish.  
**Decision:** Flutter's standard `intl`/ARB pipeline. All user-facing strings go through `AppLocalizations`. No hardcoded strings in widgets.  
**Consequences:** Extra upfront work to populate all 10 ARB files. Required for each new string. Enables future language additions with minimal friction.

---

## ADR-007: Package name ke.darkman.tafsiri
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** Standard reverse-domain Android package naming. Owner uses `ke.darkman` prefix.  
**Decision:** `ke.darkman.tafsiri`  
**Consequences:** Fixed from project creation — changing later requires a full package rename.

---

## ADR-008: STT locale derived from detected source language
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** Voice input should recognise what the user actually speaks, not the app UI language. A user with UI in German might be dictating Swahili.  
**Decision:** After each translation the detected `source_lang` is stored in controller state and mapped to a BCP-47 locale used for the next STT session. A static map covers all 10 supported languages. Falls back to device locale on first launch or unknown language.  
**Consequences:** STT quality improves significantly for multilingual users. Requires maintaining the `_sttLocaleMap`. If the device doesn't have the locale installed, `speech_to_text` falls back gracefully.

---

## ADR-009: PayPal donate button via url_launcher
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** App should offer a "Buy me a coffee" donation option consistent with the BluesoundPlayer app, using the same PayPal donate link.  
**Decision:** Add `url_launcher` dependency. Place a donate button at the bottom of the Settings screen. Opens the PayPal URL in the external browser. Button label goes through ARB localisation.  
**Consequences:** Minimal extra dependency (`url_launcher` is standard in Flutter ecosystem). No in-app payment flow, no store fees.

---

## ADR-010: App name "Tafsiri"
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** App needed a memorable, internationally distinctive name reflecting its core purpose and Swahili focus.  
**Decision:** "Tafsiri" — Swahili for "translation" (also used as a verb: "to translate"). Derived from Arabic *tafsīr*. Fully established in everyday Swahili (Kenya, Tanzania). Package name: `ke.darkman.tafsiri`.  
**Consequences:** Strong identity, directly descriptive, fits the `ke.darkman` namespace naturally.

---

## ADR-011: Norwegian locale code — `nb` not `no`
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** Flutter's `supportedLocales` uses IETF BCP-47 tags. Norwegian Bokmål is `nb`, not `no`. Using `no` causes Flutter to fail to match the locale.  
**Decision:** The ARB file is named `app_nb.arb` and the `Locale` object in `supportedLocales` is `Locale('nb')`. Display name in the locale dropdown is "Norsk", stored value is `nb`.  
**Consequences:** Consistent filename and locale code. Must be handled carefully in the locale dropdown (display "Norsk", value `nb`).

---

## ADR-012: Default AI model per provider
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** The spec does not pin specific model names. Low-cost models are appropriate for translation tasks.  
**Decision:** Default models: `claude-haiku-4-5-20251001` (Anthropic), `gpt-4o-mini` (OpenAI), `mistral-small-latest` (Mistral). Model names are hard-coded in the respective service files.  
**Consequences:** Easy to update. Low cost per translation. Quality is sufficient for the target use case.

---

## ADR-013: Source language extraction from AI response via `LANG:xx` prefix
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** The translation prompt returns only the translated text. The controller needs the detected source language to update `lastSourceLang` for STT locale mapping. A separate detection API call would violate ADR-003 (no second round-trip). Returning JSON risks the AI adding preamble.  
**Decision:** The prompt instructs the AI to respond with exactly: `LANG:[ISO-639-1 code]\n[translated text]`. The controller strips the first line, stores the code as `lastSourceLang`, and displays only the translated text.  
**Consequences:** Fragile if the AI ignores the format — mitigated by explicit prompt wording ("EXACTLY this format and nothing else"). Fallback: if the prefix is missing, `lastSourceLang` is left unchanged and STT uses the previous locale.

---

## ADR-014: SQLite migration stub from v1
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** The spec defines a v1 schema. Adding columns later without an `onUpgrade` handler causes crashes on existing installs.  
**Decision:** `db_helper.dart` includes an `onUpgrade` stub (empty body with a comment) at schema version 1. Version is incremented for each future migration.  
**Consequences:** No immediate cost. Prevents data loss bugs in future updates.

---

## ADR-015: OCR does not auto-translate
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** Voice input (STT) auto-translates on final result because the user's intent is unambiguous — they spoke to translate. OCR text from an image may contain multiple blocks, noise, or unwanted content. The user should review before translating.  
**Decision:** OCR result is placed in the input field only. The user taps Translate manually.  
**Consequences:** One extra tap for OCR users. Reduces risk of wasted API calls on poor OCR output.

---

## ADR-016: Release keystore not committed to git
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** Android release signing requires a keystore file. Committing it to a public repo is a security risk.  
**Decision:** The release keystore is generated locally and referenced via environment variables or a `key.properties` file that is listed in `.gitignore`. The `android/app/build.gradle` signing config reads from `key.properties`.  
**Consequences:** Each developer/CI environment must provision the keystore separately. Must be documented in `docs/architecture.md` or a `CONTRIBUTING.md` when CI is set up.

---

## ADR-017: Star icon tap as primary favourite interaction (not swipe)
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** The spec allows "swipe-to-favourite or star icon". Each history list item already uses swipe-to-delete (`Dismissible`). Having two swipe gestures on the same item creates an ambiguous UX.  
**Decision:** Star icon tap on the list item is the primary way to mark/unmark a favourite in v1. Swipe gesture is reserved exclusively for delete.  
**Consequences:** Cleaner gesture model. Slightly less discoverable than swipe, but the star icon is a universal convention.

---

## ADR-018: SVG-designed launcher icon with flutter_launcher_icons
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** The app needed a distinctive launcher icon. No external designer was available; the icon had to be created programmatically and integrate cleanly with Android adaptive icon requirements.  
**Decision:** Icon designed as SVG (`assets/icon/icon.svg`): two speech bubbles (solid + outline) with a directional arrow, teal `#00897B` background, rounded-square shape. Exported to 1024×1024 PNG via `inkscape`. All Android mipmap densities (mdpi → xxxhdpi) and the adaptive icon (`mipmap-anydpi-v26`) generated by `flutter_launcher_icons` dev dependency.  
**Consequences:** SVG source file is version-controlled — icon can be refined without re-exporting manually. The `flutter_launcher_icons` config lives in `pubspec.yaml`. iOS support deferred to v2.

---

## ADR-019: System dark/light theme with ThemeMode.system
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** Android users expect apps to respect the system dark/light mode preference. Hardcoding light-only would feel dated on Android 10+.  
**Decision:** `TafsiriApp` provides both `theme` and `darkTheme` via a shared `_buildTheme(Brightness)` factory, and sets `themeMode: ThemeMode.system`. Seed colour is Material teal `Colors.teal` for both modes.  
**Consequences:** No user-facing toggle needed — the system preference controls it. Both modes share the same teal identity and are visually consistent.

---

## ADR-021: AI prompt split into system role and user message
**Date:** 2026-04-11  
**Status:** Accepted  
**Context:** All three providers were receiving instructions and text in a single `user` message. ChatGPT in particular ignored the translation rules (wrong target language, reformulation instead of translation, no output for longer texts). System-role messages carry higher instruction weight with all providers.  
**Decision:** Split `buildPrompt()` into `buildSystemPrompt(targetLanguage, altLanguage)` and `buildUserMessage(text)`. Claude sends the system prompt as a top-level `"system"` field (Anthropic API standard). OpenAI and Mistral send it as `{"role": "system", ...}` as the first message. The user message contains only the raw text. `max_tokens` raised to 4096 for all providers.  
**Consequences:** Better instruction compliance across all providers. Longer OCR texts no longer truncated. `buildPrompt()` removed — any future prompt change must update `buildSystemPrompt()`.

---

## ADR-022: STT input language setting
**Date:** 2026-04-11  
**Status:** Accepted  
**Context:** STT locale was derived solely from the detected source language of the last translation (ADR-008). If the last translation detected French, the microphone would listen in French even if the user wanted to speak German. This caused mis-recognition when switching input languages.  
**Decision:** Add a `stt_language` SharedPreferences key (ISO-639-1 code, empty = auto). A dropdown in Settings lists Auto + all 10 supported languages. `TranslatorController.toggleListening()` prefers the explicit setting over the auto-detected `lastSourceLang`.  
**Consequences:** User has full control over the STT recognition locale. Auto mode (default) preserves the existing adaptive behaviour from ADR-008.

---

## ADR-023: Translation philosophy info button in ActionBar
**Date:** 2026-04-29
**Status:** Accepted
**Context:** Users were not always aware of the bidirectional translation logic (primary ↔ secondary language toggle based on detected language). A discoverable explanation directly on the translator screen was needed without cluttering the UI permanently.
**Decision:** Add a small ⓘ `IconButton` as the leftmost item in the ActionBar (between the two text areas). Tapping it opens an `AlertDialog` that explains the logic using the current primary and secondary language names as tappable links that navigate to the Settings tab. Language names are read via `ref.watch(settingsProvider)` in `build()` so they are always available immediately, even on first launch.
**Consequences:** Users can understand the translation logic on demand. Language names in the dialog always reflect current configuration. No permanent screen real estate consumed.

---

## ADR-024: Await SQLite insert before invalidating history provider
**Date:** 2026-04-29
**Status:** Accepted
**Context:** The history provider was not showing the first translation after app start. The root cause was that `dao.insert()` was called fire-and-forget via `whenData`, which returned immediately without waiting for the insert to complete. `ref.invalidate(historyProvider)` was then called before the row existed in SQLite. On subsequent translations the history provider was already alive, masking the race.
**Decision:** Replace the `whenData` fire-and-forget with a sequential `await ref.read(translationDaoProvider.future)` + `await dao.insert(...)` + `ref.invalidate(historyProvider)` block inside `translate()`. The insert is guaranteed complete before the provider is invalidated.
**Consequences:** History is consistent after every translation including the very first. Slight increase in time-to-history-refresh (one extra `await`) — negligible in practice since SQLite inserts are fast.

---

## ADR-035: Windows desktop build — bundled SQLite and a per-user Inno Setup installer
**Date:** 2026-08-14  
**Status:** Accepted  
**Context:** A Windows build was requested to test the app on Windows. Most of the desktop groundwork already exists: the platform guards from ADR-031 are keyed on `defaultTargetPlatform` and already name `TargetPlatform.windows`, the `windows/` runner scaffolding from `flutter create` is in the repo, and the plugins behave exactly as on Linux — `url_launcher`, `path_provider`, `shared_preferences`, `package_info_plus`, `file_selector`, `file_picker` and `image_picker` all have Windows implementations, while `speech_to_text` and `google_mlkit_text_recognition` have none and degrade on their own (mic button disabled, OCR reports its localised error). Two things do **not** carry over from Linux. First, `sqflite_common_ffi` loads SQLite through the `sqlite3` package, which on Windows calls `DynamicLibrary.open('sqlite3.dll')` — and Windows has no system SQLite at all, so unlike Linux there is nothing to fall back to. Second, Flutter's Windows bundle does not contain the MSVC runtime it links against, so the app fails to start on machines without the Visual C++ redistributable. Adding `sqlite3_flutter_libs` would solve the first point in one line but was rejected: it compiles a native SQLite into the **Android** build too, changing the APK's native-library set that ADR-031 through ADR-030 deliberately keep minimal for the F-Droid scanner surface — a Windows convenience must not touch the Android artefact.  
**Decision:** Ship SQLite with the Windows app instead. `windows/sqlite3.cmake` downloads the official DLL from sqlite.org at CMake configure time (pinned to 3.53.4, verified against the SHA3-256 hash published on the download page — sqlite.org lists SHA3, not SHA256), caches it in the git-ignored `windows/third_party/`, and `windows/CMakeLists.txt` installs it next to `tafsiri.exe` so the default Windows DLL search order finds it. `useSystemSqlite` gains a Windows branch that tries the DLL beside `Platform.resolvedExecutable`, then the repo-local cache (so `flutter test` works from a checkout, where the running executable is the Dart VM), then the bare name, and otherwise throws a message naming what it tried. The MSVC runtime is pulled from the local Visual Studio install via CMake's `InstallRequiredSystemLibraries` and installed alongside. Packaging is Inno Setup (`windows/installer/tafsiri.iss`) with `PrivilegesRequired=lowest`, i.e. a per-user install into `%LOCALAPPDATA%\Programs\Tafsiri` with no admin rights and no UAC prompt — the same "no root required" stance as `install.sh` on Linux (ADR-032). `build_windows.ps1` is the entry point: it reads the version from `pubspec.yaml`, builds, asserts the bundle actually contains `sqlite3.dll`, and compiles the installer. `Runner.rc`'s `ProductName` becomes `Tafsiri` and the window title is `Tafsiri` rather than the lower-case package name; `app_icon.ico` is regenerated from `assets/icon/icon_1024.png` at 7 sizes.  
**Consequences:** `.\build_windows.ps1` produces `build\windows\installer\tafsiri-<version>-windows-x64.exe`, and the tagged-release workflow builds it on `windows-latest`. Uninstalling asks — in the installer's language — whether to keep settings, API keys and history, defaulting to keep; they live in `%APPDATA%\ke.darkman\Tafsiri`, which `path_provider` derives from `CompanyName`/`ProductName` in the version resource, so **that path is coupled to `Runner.rc`** and changing either name orphans existing user data. The build needs internet access on its first configure per architecture; the error message tells you how to place the DLL by hand if not. The pinned SQLite version has to be bumped manually — with three hashes, since x64, arm64 and x86 are pinned separately. Inno Setup 6.3+ is required (`ArchitecturesAllowed=x64compatible`); the installer is offered in 8 of the app's 10 languages, because Inno ships no Swahili or Swedish translation. Android, Linux and the `pubspec.yaml` dependency set are untouched, and the 95-test suite is unaffected.

---

## ADR-034: Settings and history survive a reinstall via a manual backup file
**Date:** 2026-08-12  
**Status:** Accepted  
**Context:** On Android, everything the app owns — `SharedPreferences` and the SQLite history — lives in the app sandbox and is deleted with the app. Reinstalling means re-typing three API keys and losing every saved translation. (On Linux this is already handled: `install.sh --uninstall` deliberately keeps `~/.local/share/ke.darkman.tafsiri/`, ADR-032.) Android's Auto Backup is nominally on, since the manifest sets no `android:allowBackup` and the platform default is `true`, but it is the wrong tool here: it needs a Google account with Drive backup enabled, runs on the system's schedule so you never know whether a usable copy exists, is unreliable for sideloaded APKs — which is exactly how this app is distributed — and it would ship the user's API keys to Google's servers as a side effect of a convenience feature.  
**Decision:** A manual **backup file** instead: Settings gains a Backup section with "Save backup" and "Restore backup". The document is indented JSON, tagged `"app": "tafsiri-backup"` with a `formatVersion`, holding the settings, the full history including correction notes and favourites, and — only when the user flips a switch that defaults to off — the API keys. `BackupService` is pure data transformation (build/parse, no I/O) so the format is pinned by unit tests; `BackupController` owns the dialogs and the applying; `BackupFileIo` isolates the file dialogs behind two methods, which also makes the controller testable with a fake. Restoring **replaces** the settings; for the history the user picks between two modes with a switch that sits next to the include-keys one. The default is **merge** — `TranslationDao.insertMissing` skips entries whose source text, result text and timestamp already exist, so importing the same file twice is a no-op instead of doubling everything, which is what you want when pulling in a second device's translations. **Replace** (`replaceAllWith`, delete + insert in one transaction so a failure cannot leave the user with neither history) is for restoring a device to a known state. Merge is the default because it cannot destroy anything; replace is destructive and irreversible, so it gets its own dialog wording and a red confirm button, and the switch resets to off every time rather than being persisted. A backup written without keys must not blank the keys already configured, so `SettingsController.restore` takes an explicit `restoreApiKeys` flag rather than inferring it from empty strings. Parsing is deliberately lenient about content and strict about identity: a missing settings block falls back to defaults and an unusable history row is dropped, but a file that is not marked as ours, or carries a newer `formatVersion`, is rejected outright.  
**Consequences:** The two file-dialog plugins are split by platform on purpose, and neither could do the job alone. `file_selector` has no save dialog on Android at all (its own support table marks "Choose a save location" unsupported there), and `file_picker` shells out to `zenity`/`qarma` on Linux — not installed on the maintainer's own KDE desktop, which ships `kdialog` — so its Linux path fails on ordinary machines. Linux therefore uses `file_selector` (native GTK, no external binary; verified: only `file_selector_linux` is registered in `generated_plugin_registrant.cc`) and Android uses `file_picker` (Storage Access Framework, no permissions needed). Both write outside the sandbox, which is the whole point. The cost is two dependencies for one feature. The backup is plain text: with keys included it is a secret and the UI says so in red at the moment the switch is flipped. This also doubles as the migration path between Android and Linux, which Auto Backup could never have provided. `android:allowBackup` is left at its default rather than being turned off — belt and braces for users who do have Google backup working.

---

## ADR-033: Correction mode — improve primary-language input instead of translating it
**Date:** 2026-08-12  
**Status:** Accepted  
**Context:** A learner writing in the primary language (Swahili by default) does not want that text translated back into the secondary language — they want to know whether what they wrote is right. The existing bidirectional logic (ADR-003) makes that impossible: primary-language input always goes to the alternative language. A second case matters just as much: input like `Tafadhali nipe Butter.` is Swahili apart from one word the learner did not know and substituted from another language. Translating the whole sentence is useless there; replacing "Butter" with "siagi" is exactly what is wanted.
**Decision:** Add a **correction mode**, toggled by a `FilterChip` in the translator header (not buried in Settings — it is flipped per input session) and persisted under `correction_mode` in `SharedPreferences`, so it survives restarts. When enabled, `AiService.translate()` receives `correctionMode: true` and every provider sends a different system prompt (`buildCorrectionSystemPrompt`) instead of the translation prompt. That prompt lets the **model** decide the branch, so no second round-trip and no local language detection is needed: text predominantly in the primary language is rewritten as a native speaker would write it — with foreign words explicitly treated as vocabulary gaps to be replaced — while anything else is still translated to the primary language, exactly as before. The response protocol of ADR-013 is extended with two optional lines: `MODE:correct|translate` after `LANG:xx`, and a trailing `NOTES:` section holding one bullet per change, written in the **secondary** language (the learner's stronger language). Parsing moves out of the two private `_extract*` helpers into a testable `AiResult.parse()`. `OutputArea` shows the notes under a "Suggestions" heading below the corrected text; the copy button still copies the corrected text only. The toggle (state) and the action button (verb) must not share an icon: the chip uses `Icons.spellcheck`, the button `Icons.auto_fix_high`. The first version gave both the spellcheck icon and the very first user question was "what does this second button do?" — a widget test now pins the two icons apart. The chip's on/off state is likewise not left to colour alone: the label carries it in words (`Correction mode (on)` / `(off)`) and the selected chip is filled with `colorScheme.primary`, because Material's default `secondaryContainer` fill is nearly indistinguishable from the unselected chip on a light background. Schema version goes to 2 with `mode` and `notes` columns (`ALTER TABLE ... DEFAULT 'translate'`, so old rows migrate as translations) and history marks correction entries with a spellcheck badge. `DbHelper.createTableSql`/`migrate` are now public and shared with the tests, which previously duplicated the DDL and would have silently drifted.
**Consequences:** Correction mode costs one API call, same as a translation. The translation path is byte-for-byte unchanged when the mode is off — the old prompt is still used and the `MODE:`/`NOTES:` lines never appear, which keeps the regression surface at zero and is asserted by a test. Quality of the corrections depends on the provider's grasp of the primary language, which for Swahili is the weakest link (this is the same bet ADR-003 already makes for detection). Notes are written in the secondary language rather than the UI locale: for the intended setup (learner practises the primary, speaks the secondary) these coincide, and it avoids plumbing the app locale into the service layer — revisit if users set an app locale unrelated to both. The mode is deliberately not exposed per history entry: reloading a correction restores its notes, but re-running it uses whatever mode is currently active.

---

## ADR-030: Abandon official F-Droid; restore image-to-text (OCR)
**Date:** 2026-06-14  
**Status:** Accepted (supersedes ADR-028, ADR-029)  
**Context:** After removing OCR (ADR-028) the `fdroid build` job passed, but the `check apk` scanner then rejected 6 proprietary `com.google.android.play.core.*` classes that Flutter's embedding bundles for Play Store deferred components (ADR-029). Excluding the dependency was a no-op locally (R8 strips the classes regardless), and F-Droid's build keeps them — a difference in R8 behaviour that could **not be reproduced or verified locally**, turning further fixes into blind tag-and-pray against F-Droid CI. Combined with the value already lost (OCR), the cost/benefit no longer justified chasing official F-Droid inclusion. This is a long-standing, unresolved Flutter limitation ([flutter#104219](https://github.com/flutter/flutter/issues/104219)).  
**Decision:** Stop pursuing the official F-Droid repo. Close MR #39249. Restore the image-to-text/OCR feature (`google_mlkit_text_recognition` + `image_picker`, the image button + camera/gallery sheet, OCR controller logic/state, OCR ARB strings, CAMERA/READ_MEDIA_IMAGES/READ_EXTERNAL_STORAGE permissions, ML Kit ProGuard rules, store-description mentions). Remove the now-pointless Play Core exclusion from `build.gradle.kts`. Released as 1.0.8 (versionCode 8). The app is **not published to F-Droid**; distribution stays Play Store / direct APK / GitHub releases.  
**Consequences:** Full feature set is back (photo→text translation restored). The `android.newDsl=false` / `android.builtInKotlin=false` flags are kept (harmless, and useful if the build toolchain ever moves to AGP 9). The `fdroid/` recipe and fastlane metadata remain as historical artifacts but are unused. If FOSS-store distribution is ever wanted again, IzzyOnDroid (builds from GitHub release APKs, allows NonFree deps) is the path that keeps OCR — not the official F-Droid repo.

---

## ADR-032: Linux installer — name the desktop entry after the Wayland app_id
**Date:** 2026-07-29  
**Status:** Accepted  
**Context:** The Linux build (ADR-031) produces a bare bundle directory with no menu integration. The sibling BluesoundPlayer project solved the same problem with a per-user `install.sh` into `~/.local`, and its convention is worth mirroring — but its `.desktop` file uses `StartupWMClass=bluesoundplayer_flutter`, i.e. the binary name. That is correct *there* and wrong here: BluesoundPlayer's `my_application.cc` has no `g_set_prgname`, so its Wayland `app_id` falls back to the binary name, whereas Tafsiri's newer Flutter template calls `g_set_prgname(APPLICATION_ID)` (`linux/runner/my_application.cc:124`). Under Wayland a compositor maps a window to its desktop entry by matching `app_id` against the `.desktop` basename; get it wrong and the app shows a generic placeholder icon in the dash and task switcher. Copying the neighbour's naming verbatim would have reproduced exactly the icon bug the script exists to avoid.  
**Decision:** Add `install.sh` at the repo root, modelled on BluesoundPlayer's (per-user `~/.local` install, hicolor icons, `gtk-update-icon-cache` + `update-desktop-database`), but with every user-visible name derived from `APP_ID=ke.darkman.tafsiri`: the entry is `ke.darkman.tafsiri.desktop`, `Icon=ke.darkman.tafsiri`, and `StartupWMClass=ke.darkman.tafsiri` (the latter covers the XWayland/X11 fallback). Icons are rasterised from `icon_1024.png` at 8 sizes plus the SVG into `scalable/` for HiDPI; the rasteriser degrades ImageMagick → Pillow → plain copy. The script also auto-detects and clears the stale-`CMAKE_INSTALL_PREFIX` build tree described in ADR-031, and offers `--rebuild` / `--uninstall`. `Categories=Utility;TextTools;Dictionary;` — a single main category, so the entry cannot appear twice in the menu.  
**Consequences:** `./install.sh` gives a menu entry with a correct icon under Wayland, no root needed. `desktop-file-validate` passes with no warnings. Uninstall removes only what the script installed and deliberately keeps `~/.local/share/ke.darkman.tafsiri/` (settings + history) — note that this data directory is distinct from the install directory `~/.local/share/tafsiri/`. Two bugs were found and fixed while verifying: `set -o pipefail` combined with `grep -q` made the SQLite runtime check fail on every machine (`grep -q` exits early, `ldconfig` gets SIGPIPE 141), and `Categories=Utility;Office;` declared two main categories. The install is per-user only; system-wide packaging (AppImage/Flatpak/.deb) remains open.

---

## ADR-031: Linux desktop build — sqflite via FFI against the system SQLite
**Date:** 2026-07-29  
**Status:** Accepted  
**Context:** A Linux desktop build was requested. The GTK runner scaffolding from `flutter create` was already in the repo and the toolchain only needed `libgtk-3-dev`. Of the plugins, `url_launcher`, `path_provider`, `shared_preferences`, `package_info_plus` and `image_picker` all have endorsed Linux implementations, but three do not: `sqflite` (Android/iOS only), `speech_to_text` (no Linux) and `google_mlkit_text_recognition` (Android/iOS only). STT and OCR degrade on their own — the mic button is already disabled when `isSttAvailable` is false, and `pickImageAndRecognize` is wrapped in `try/catch` and surfaces `ocrError`. `sqflite` does not degrade: it would throw `MissingPluginException` on every history read and on every translation save, i.e. the app is broken. Additionally, `sqflite_common_ffi` delegates library loading to `sqlite3`, which on Linux only tries the unversioned `libsqlite3.so` — that soname ships in `libsqlite3-dev`, which end users do not have; the runtime package provides `libsqlite3.so.0`. This was already visible as 8 permanently failing `translation_dao_test` cases.  
**Decision:** Add `lib/core/database/sqflite_desktop.dart`, which builds the FFI factory via `createDatabaseFactoryFfi(ffiInit: useSystemSqlite)` and is invoked from `main()`. `useSystemSqlite` registers a `sqlite3` loader override that tries `libsqlite3.so` then `libsqlite3.so.0`. It must be a top-level function and be passed as `ffiInit`, because `sqflite_common_ffi` executes SQLite in a worker isolate where an override registered on the main isolate does not apply. `DbHelper` resolves its directory via `getApplicationSupportDirectory()` on desktop, since the FFI factory's `getDatabasesPath()` otherwise resolves relative to the working directory. `sqflite_common_ffi` moved from dev- to regular dependency; `sqlite3` added as a direct dependency. All guards are keyed on `defaultTargetPlatform`, so mobile behaviour is untouched.  
**Consequences:** `flutter build linux --release` produces a 52 MB relocatable bundle that only needs the ubiquitous `libsqlite3-0` at runtime — no `-dev` package, no bundled SQLite. The 8 DAO tests now pass (45/45 green), and `test/database/sqflite_desktop_test.dart` guards the isolate/loader wiring against regression. `sqlite3` and `sqflite_common_ffi` are pure-Dart FFI packages with no Android native code: the release APK's native libraries are unchanged (`libapp.so`, `libdatastore_shared_counter.so`, `libflutter.so`, `libmlkit_google_ocr_pipeline.so`), so the F-Droid/scanner surface from ADR-028/029/030 is unaffected. On Linux the app runs with **no voice input** (button disabled) and **no OCR** (image picking works via `image_picker_linux`/`file_selector`, but recognition fails with the localised OCR error); camera as an image source is meaningless there. Because `sqflite_desktop.dart` imports `dart:ffi`/`dart:io`, `main.dart` is no longer web-compilable — web was never a target (ML Kit alone rules it out) and is not in the v1 scope.

**Build note:** if a Linux configure fails before reaching the install block (e.g. missing GTK), CMake still writes a `CMakeCache.txt` pinning `CMAKE_INSTALL_PREFIX=/usr/local`. Because Flutter's `linux/CMakeLists.txt` only overrides the prefix when `CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT` is set — true only on the *first* configure in a build tree — every later build then tries to install into `/usr/local` and dies with "Permission denied". Fix: `rm -rf build/linux` and rebuild.

---

## ADR-029: Exclude Google Play Core to pass F-Droid's APK scanner
**Date:** 2026-06-14  
**Status:** Accepted  
**Context:** After removing ML Kit (ADR-028), the `fdroid build` job finally succeeded — but the pipeline's `check apk` job (which only runs once a build exists, hence never seen before) failed: the scanner found 6 proprietary classes in the APK — `com.google.android.play.core.splitcompat.SplitCompatApplication`, `…splitinstall.SplitInstallManager`/`SplitInstallSessionState`/`SplitInstallStateUpdatedListener`, `…tasks.OnSuccessListener`/`OnFailureListener`. These come from Google Play Core, which Flutter's embedding pulls in for Play Store "deferred components" / dynamic feature delivery. Tafsiri does not use deferred components. (Note: these are the same classes the `-dontwarn` rules reference — they are referenced by Flutter's `PlayStoreDeferredComponentManager` but the app never instantiates it.)  
**Decision:** Add `configurations.all { exclude(group = "com.google.android.play") }` to `android/app/build.gradle.kts`. The `-dontwarn com.google.android.play.core.**` ProGuard rules remain so R8 does not fail on the now-absent classes. Released as 1.0.7 (versionCode 7); F-Droid recipe pinned to tag `v1.0.7` (1.0.6 was tagged but never published — its APK failed `check apk`).  
**Consequences:** The APK no longer contains any `com.google.android.play.core` classes — verified locally with `dexdump` (0 class definitions) under the reproduced F-Droid AGP 9 toolchain. Deferred components remain unavailable (unused anyway). This exclusion is harmless for any other distribution channel.

---

## ADR-028: Remove image-to-text (OCR) for F-Droid compatibility
**Date:** 2026-06-14  
**Status:** Accepted  
**Context:** Even after fixing the AGP 9 / built-in-Kotlin opt-out (ADR-027), the F-Droid build kept failing while configuring `:google_mlkit_commons`. The F-Droid job log revealed the real cause: F-Droid's scanner logs `Removing usual suspect 'com.google.mlkit'` and **strips every `com.google.mlkit:*` dependency** from the ML Kit plugins' `build.gradle` (ML Kit is proprietary Google software pulled from Google's Maven; it is on F-Droid's `suss.json` non-free signature list). Proven locally: replicating the strip produces 23 compile errors (`package com.google.mlkit.* does not exist`). No Gradle flag or plugin-version bump can fix this — it is a licensing/policy incompatibility. ML Kit was the **only** non-free dependency flagged; everything else (speech_to_text via the system SpeechRecognizer, the AI HTTP calls, sqflite, etc.) is F-Droid-clean. Options considered: ship via IzzyOnDroid (keeps ML Kit, builds from GitHub release APKs); replace ML Kit with FOSS Tesseract (heavy — the Flutter plugins pull a prebuilt tesseract4android AAR that F-Droid also rejects, plus photo-OCR quality regression); or remove the OCR feature.  
**Decision:** Remove the image-to-text/OCR feature for the official F-Droid distribution: drop `google_mlkit_text_recognition` and `image_picker`, the image button + camera/gallery sheet, the OCR controller code/state, the OCR ARB strings, the CAMERA/READ_MEDIA_IMAGES/READ_EXTERNAL_STORAGE permissions, and the ML Kit ProGuard rules. The Google Play Core `-dontwarn` rules are kept — they belong to Flutter's `PlayStoreDeferredComponentManager`, not ML Kit. Released as 1.0.6 (versionCode 6), F-Droid recipe pinned to tag `v1.0.6`.  
**Consequences:** The app loses photo→text translation; voice, paste, typing, AI translation, history, favourites and 10-language UI remain. APK ~84 MB → ~53 MB. Verified buildable under the reproduced F-Droid AGP 9 toolchain. If OCR is wanted back later, the cleanest path is a separate IzzyOnDroid distribution that keeps ML Kit (no source build, no stripping). The opt-out Gradle flags from ADR-027 are still required (the kotlin-android conflict is a project-level AGP 9 issue, independent of ML Kit).

---

## ADR-027: F-Droid build fix — opt out of both AGP 9 new DSL and built-in Kotlin
**Date:** 2026-06-14  
**Status:** Accepted  
**Context:** The F-Droid `fdroid build` job for MR #39249 kept failing with a `NullPointerException` while configuring `:google_mlkit_commons` ("Failed to notify project evaluation listener") plus a Flutter Fix hint "Starting AGP 9+, only the new DSL interface will be read". Three prior commits (ee2b338, 28eed06, d2afa69) only varied *how* `android.newDsl=false` was applied and never fixed it. Root cause was established by reproducing the build locally: the project pins AGP 8.7.3 + Gradle 8.12 and builds fine under that toolchain (Java 17 *and* full JDK 21), but F-Droid's buildserver pulls `fdroidserver` from `master` and builds with a **bleeding-edge AGP 9 / Gradle 9** toolchain that activates the new Gradle DSL and built-in Kotlin. Under AGP 9, `android.newDsl=false` alone is insufficient — it leaves a `kotlin-android` "Cannot add extension with name 'kotlin'" failure. The old `google_mlkit_commons` 0.8.1 (legacy embedded `buildscript { classpath 'com.android.tools.build:gradle:7.4.2' }`) is the component that NPEs first on F-Droid's exact version mix.  
**Decision:** Set BOTH `android.newDsl=false` and `android.builtInKotlin=false` in `android/gradle.properties`, and append both in the F-Droid recipe prebuild (the recipe builds the v1.0.5 tag, whose committed file predates these flags). Verified locally: AGP 9.0.1 + Gradle 9.1.0 + JDK 21 + the unchanged old plugin builds a clean ~84 MB APK with both flags, and fails with only `newDsl=false`. The flags are no-ops under AGP 8.7.3, so they are safe regardless of which toolchain F-Droid uses on a given day.  
**Consequences:** No retag needed — only the prebuild changed, so updating the fdroiddata MR YAML is enough to re-trigger CI. A proper migration to the AGP 9 / new-DSL world (and newer MLKit plugins) is deferred; the opt-out flags will stop working at AGP 10 (mid-2026), tracked in todo. The misleading note in `docs/FDROID.md` claiming `fdroid build` "fails for Flutter apps (expected)" was corrected — it must pass.

---

## ADR-026: F-Droid submission
**Date:** 2026-05-28  
**Status:** Accepted  
**Context:** Tafsiri should be available via F-Droid, the open-source Android app store, to reach users who prefer FOSS distribution over Google Play.  
**Decision:** Prepare the app for F-Droid's source-based build model. Changes required: `dependenciesInfo { includeInApk = false; includeInBundle = false }` in `build.gradle.kts` (mandatory for F-Droid); Java compatibility raised to VERSION_17 (F-Droid builds with Java 21); fastlane store metadata in en-US, de-DE, sw; F-Droid build recipe at `fdroid/metadata/com.njerahouse.tafsiri.yml`; GitHub Actions release workflow with pinned Flutter version. Anti-feature `NonFreeNet` declared because the app connects to third-party AI APIs. MR submitted to `fdroid/fdroiddata`: https://gitlab.com/fdroid/fdroiddata/-/merge_requests/39249  
**Consequences:** F-Droid builds the APK from source using its own signing keys — no pre-built APK is submitted. Auto-updates work via git tags (`v1.x.y`). The `NonFreeNet` anti-feature is displayed in the F-Droid store listing but does not block inclusion. The `google_mlkit_text_recognition` dependency uses the unbundled ML Kit (Apache 2.0) which does not require Google Play Services.

---

## ADR-025: API key console links and Mistral free-tier hint in Settings
**Date:** 2026-05-28  
**Status:** Accepted  
**Context:** The "bring your own API key" model requires users to obtain keys from each provider's console. New users had no guidance on where to get a key or that a free option exists.  
**Decision:** Add a "Get API key →" `TextButton` below the active provider's API key field. Each provider maps to its canonical key console URL (Mistral: `console.mistral.ai/api-keys`, Claude: `console.anthropic.com/settings/keys`, OpenAI: `platform.openai.com/api-keys`). For Mistral specifically, a hint text notes the free tier with no credit card required — Mistral is the default provider and the only one with a free offering. All text goes through ARB localisation (11 locales).  
**Consequences:** Friction for new users is reduced significantly. URL constants centralised in `constants.dart`. If provider console URLs change they must be updated there.

---

## ADR-020: ProGuard keep rules for google_mlkit_text_recognition release build
**Date:** 2026-04-10  
**Status:** Accepted  
**Context:** `flutter build apk --release` failed with R8 errors: the `google_mlkit_text_recognition` plugin references optional script-recognizer classes (Chinese, Devanagari, Japanese, Korean) and Google Play Core split-install classes that are not bundled in the base Latin-script SDK. R8 treats missing references as fatal errors.  
**Decision:** Add `-dontwarn` rules for all missing classes to `android/app/proguard-rules.pro`. Enable `isMinifyEnabled = true` with `proguardFiles` reference in the release build type. The optional script models are not shipped — the app only uses Latin-script OCR.  
**Consequences:** Release build succeeds. Optional script recognizers remain unsupported in v1 (out of scope). If Chinese/Japanese/Korean OCR is added in v2, the corresponding SDK dependency must be added and the `-dontwarn` rule removed.
