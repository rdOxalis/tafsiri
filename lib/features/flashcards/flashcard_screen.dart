import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/languages.dart';
import 'flashcard.dart';
import 'flashcard_controller.dart';
import 'scheduler.dart';

/// A learning session with the flashcards from the favourites (ADR-082).
class FlashcardScreen extends ConsumerWidget {
  const FlashcardScreen({super.key, required this.pair});

  /// The language pair this session learns (ADR-083).
  final LanguagePair pair;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(learnProvider(pair));

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.learnTitle} · ${pairLabel(pair)}'),
        actions: [
          if (state.total > 0 && state.phase != LearnPhase.done)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('${state.position}/${state.total}')),
            ),
        ],
      ),
      body: SafeArea(
        child: switch (state.phase) {
          LearnPhase.loading =>
            const Center(child: CircularProgressIndicator()),
          LearnPhase.nothingDue => _Message(text: l10n.learnNothingDue),
          LearnPhase.done => _Summary(state: state),
          _ => _CardView(pair: pair, state: state),
        },
      ),
    );
  }
}

class _CardView extends ConsumerStatefulWidget {
  const _CardView({required this.pair, required this.state});

  final LanguagePair pair;
  final LearnState state;

  @override
  ConsumerState<_CardView> createState() => _CardViewState();
}

class _CardViewState extends ConsumerState<_CardView> {
  final _answer = TextEditingController();

  @override
  void didUpdateWidget(_CardView old) {
    super.didUpdateWidget(old);
    // A new card starts with an empty field.
    if (old.state.position != widget.state.position) _answer.clear();
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = widget.state;
    final notifier = ref.read(learnProvider(widget.pair).notifier);
    final card = state.card!;
    final asking = state.phase == LearnPhase.asking;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(card.prompt, style: theme.textTheme.headlineSmall),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.learnTranslateInto(state.answerLanguage),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        if (asking) ...[
          TextField(
            controller: _answer,
            autofocus: true,
            minLines: 2,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: l10n.learnAnswerHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => notifier.submit(''),
                child: Text(l10n.learnDontKnow),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => notifier.submit(_answer.text),
                child: Text(l10n.learnCheck),
              ),
            ],
          ),
        ] else if (state.phase == LearnPhase.checking) ...[
          _Labelled(
            label: l10n.learnYourAnswer,
            text: state.answer.trim().isEmpty ? l10n.learnNoAnswer : state.answer,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(l10n.learnChecking),
            ],
          ),
        ] else
          _Result(pair: widget.pair, state: state),
      ],
    );
  }
}

class _Result extends ConsumerWidget {
  const _Result({required this.pair, required this.state});

  final LanguagePair pair;
  final LearnState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final notifier = ref.read(learnProvider(pair).notifier);
    final verdict = state.verdict;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Labelled(
          label: l10n.learnYourAnswer,
          text: state.answer.trim().isEmpty ? l10n.learnNoAnswer : state.answer,
        ),
        const SizedBox(height: 12),
        // The answer to learn from — after "I don't know" the only thing
        // that matters on this screen — so it stands out from the rest.
        Container(
          key: const ValueKey('saved-translation'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.learnSaved,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                state.card!.expected,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (verdict != null && verdict.feedback.isNotEmpty) ...[
          Text(verdict.feedback, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
        ],
        Text(
          state.aiUnavailable ? l10n.learnAiUnavailable : l10n.learnOverrideHint,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        SegmentedButton<Grade>(
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: Grade.wrong, label: Text(l10n.gradeWrong)),
            ButtonSegment(value: Grade.almost, label: Text(l10n.gradeAlmost)),
            ButtonSegment(value: Grade.correct, label: Text(l10n.gradeCorrect)),
          ],
          selected: {if (state.grade != null) state.grade!},
          onSelectionChanged: (s) {
            if (s.isNotEmpty) notifier.setGrade(s.first);
          },
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: state.grade == null ? null : notifier.next,
            child: Text(l10n.learnNext),
          ),
        ),
      ],
    );
  }
}

class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(text, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final LearnState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.learnSessionDone, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              l10n.learnSummary(
                state.counts[Grade.correct] ?? 0,
                state.counts[Grade.almost] ?? 0,
                state.counts[Grade.wrong] ?? 0,
              ),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.learnFinish),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
}

/// "Kiswahili – Deutsch": a pair in the languages' own names.
String pairLabel(LanguagePair pair) =>
    '${languageDisplayName(pair.first)} – ${languageDisplayName(pair.second)}';
