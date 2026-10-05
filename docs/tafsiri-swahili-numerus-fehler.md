# Tafsiri: Fehler bei Numerus-Erkennung im Swahili (Objekt-/Subjektpräfixe)

## Kontext

Bei manuellen Tests von Tafsiri (Swahili → Deutsch) ist ein systematischer Fehler aufgefallen: Das Modell erkennt den Plural nicht, wenn er nur am Verb markiert ist. Das betrifft vor allem Nomen der N-Klasse (Klasse 9/10), die im Singular und Plural identisch sind. Bei solchen Nomen steckt die Numerus-Information **ausschließlich** in den Subjekt- und Objektpräfixen des Verbs.

Die Aufgabe: Ursache verstehen, Prompt/Pipeline so anpassen, dass Verben morphologisch korrekt zerlegt werden, und Regressionstests ergänzen.

## Beobachtete Fehler

### Fall 1 – Erklärungsmodus aus

- **Eingabe:** `Salim aliwapatia paka chakula tayari`
- **Tafsiri:** „Salim gab der Katze bereits Futter / Salim hat der Katze schon Futter gegeben.“
- **Korrekt:** „Salim gab **den Katzen** bereits Futter.“

### Fall 2 – Erklärungsmodus an

- **Eingabe:** `Salim ameshawapatia paka chakula`
- **Tafsiri:** „Salim hat der Katze bereits das Futter gegeben.“
- **Erklärung von Tafsiri:**
  - `-meshawapatia (Verb, Perfekt von -wapatia) — hat bereits gegeben`
  - `paka (Substantiv, Klasse 9/10) — Katze`
  - `chakula (Substantiv, Klasse 7/8) — Futter / Mahlzeit`
- **Korrekt:** „Salim hat **den Katzen** bereits Futter gegeben.“

Die Erklärung zeigt die Ursache: Das Verb wird nicht wirklich in Morpheme zerlegt.

- Das Subjektpräfix `a-` fehlt.
- `-wa-` wird als Teil des Verbstamms behandelt („Perfekt von -wapatia“). Ein Verb `-wapatia` existiert nicht.
- `-sha-` (bereits) wird nicht als eigenes Morphem ausgewiesen.

## Korrekte Analyse

`a-me-sha-wa-patia`

| Morphem | Funktion |
|---|---|
| `a-` | Subjektpräfix, 3. Sg. (er/sie → Salim) |
| `-me-` | Perfekt |
| `-sha-` | „bereits, schon“ |
| `-wa-` | Objektpräfix, 3. Pl. Lebewesen (ihnen) |
| `-patia` | Stamm: geben (Applikativ von `pata`) |

`aliwapatia` = `a-li-wa-patia` → `-li-` = Vergangenheit, sonst gleich.

## Die relevante Grammatikregel

1. Nomen der N-Klasse (9/10) haben keinen sichtbaren Plural: *paka, mbwa, ndege, simba, rafiki, ng'ombe* …
2. **Lebewesen** nehmen unabhängig von ihrer Nominalklasse die Übereinstimmung der Personenklasse (1/2, m-/wa-):
   - Objekt: `-m-` / `-mw-` = Singular, `-wa-` = Plural
   - Subjekt: `a-` = Singular, `wa-` = Plural
   - Adjektive: `paka mdogo` (Sg.) vs. `paka wadogo` (Pl.)
3. Daraus folgt: Bei solchen Nomen **muss** der Numerus aus den Verbpräfixen (oder Adjektiven) abgeleitet werden, nicht aus dem Nomen.
4. Mehrdeutigkeit beachten: `-wa-` als Objekt kann auch „euch“ (2. Pl.) bedeuten. Aufgelöst wird das durch Kontext, ein Bezugsnomen oder z. B. ein folgendes Verb mit `m-` (2. Pl.) bzw. die Endung `-ni`.
   - Beispiel: `Niliwakuta mkitembea` = „Ich traf **euch** beim Spazierengehen an“ (wegen `m-` in `mkitembea`).
   - `Niliwakuta wakitembea` = „Ich traf **sie** beim Spazierengehen an.“

## Vermutete Ursachen

Welches Modell und welcher Prompt Tafsiri aktuell verwendet, bitte im Code prüfen. Wahrscheinliche Faktoren:

1. **Modellgröße:** Ein kleines/schnelles Modell hat bei Swahili-Morphologie (weniger Trainingsdaten) deutlich weniger Tiefe.
2. **Keine Analyse vor der Ausgabe:** Das Modell übersetzt direkt aus dem Gesamtbild. Das Nomen *paka* „sieht nach Singular aus“, also gewinnt der Singular.
3. **Falsche Reihenfolge im Erklärungsmodus:** Es scheint erst übersetzt und dann erklärt zu werden. Die Erklärung rechtfertigt dann nur noch die bereits gewählte (falsche) Übersetzung.
4. **Kein grammatischer Kontext im Prompt:** Das Modell bekommt keinen Hinweis auf die Präfix-Regel.

## Lösungsansätze

1. **Analyse vor Übersetzung erzwingen (wichtigster Punkt):**
   Strukturierte Ausgabe (JSON-Schema / Tool-Use), in der das Modell **zuerst** jedes Verb in feste Slots zerlegt und **danach** übersetzt. Vorschlag für Verb-Felder:
   - `surface` (z. B. `ameshawapatia`)
   - `subject_prefix` + `subject_person_number`
   - `tense_marker` (`li`, `me`, `na`, `ta`, `ki`, …)
   - `aspect_marker` (z. B. `sha`)
   - `object_prefix` + `object_person_number`
   - `stem`
   - `extension` (Applikativ, Kausativ, Passiv …)
   - `object_number` / `subject_number` explizit als `singular` / `plural` / `ambiguous`

   Die Übersetzung muss sich auf diese Felder stützen. Die Erklärung für den Nutzer wird aus derselben Analyse generiert – das macht sie zugleich lehrreicher.

2. **Prompt-Regel ergänzen:** Explizit anweisen, bei Nomen ohne sichtbaren Plural (N-Klasse, Lehnwörter) und bei Lebewesen den Numerus aus Subjekt-/Objektpräfixen abzuleiten (`-m-/-mw-` vs. `-wa-`, `a-` vs. `wa-`).

3. **Mehrdeutigkeit sichtbar machen:** Wenn `-wa-` ohne eindeutigen Bezug steht (sie vs. euch), im Erklärungsmodus darauf hinweisen statt still zu raten.

4. **Modell/Thinking vergleichen:** Dieselben Testsätze mit dem aktuellen Modell, einem größeren Modell und mit aktiviertem Extended Thinking laufen lassen. So zeigt sich, ob das Problem am Modell oder am Prompt liegt, und was die bessere Genauigkeit pro Anfrage kostet.

## Regressionstests

Erwartung jeweils: korrekter Numerus in der deutschen Übersetzung.

| Swahili | Erwartet (Deutsch) | Prüft |
|---|---|---|
| `Salim alimpatia paka chakula` | … gab **der Katze** Futter | Objekt Sg. `-m-` |
| `Salim aliwapatia paka chakula` | … gab **den Katzen** Futter | Objekt Pl. `-wa-` |
| `Salim ameshawapatia paka chakula` | … hat **den Katzen** bereits Futter gegeben | `-me-` + `-sha-` + `-wa-` |
| `Salim ameshawapa paka chakula` | … hat **den Katzen** bereits Futter gegeben | Stamm `-pa` statt `-patia` |
| `Mbwa analala` | **Der Hund** schläft | Subjekt Sg. `a-` |
| `Mbwa wanalala` | **Die Hunde** schlafen | Subjekt Pl. `wa-` |
| `Nilimwona rafiki` | Ich sah **den Freund / die Freundin** | Objekt Sg. `-mw-` |
| `Niliwaona rafiki` | Ich sah **die Freunde** | Objekt Pl. `-wa-` |
| `Paka mdogo analala` | **Die kleine Katze** schläft | Adjektiv + Subjekt Sg. |
| `Paka wadogo wanalala` | **Die kleinen Katzen** schlafen | Adjektiv + Subjekt Pl. |
| `Niliwakuta mkitembea` | Ich traf **euch** beim Spazierengehen an | `-wa-` = 2. Pl., aufgelöst durch `m-` |
| `Niliwakuta wakitembea` | Ich traf **sie** beim Spazierengehen an | `-wa-` = 3. Pl. |

Zusätzlich im Erklärungsmodus prüfen, dass die Zerlegung von `ameshawapatia` alle fünf Morpheme (`a-me-sha-wa-patia`) korrekt ausweist.
