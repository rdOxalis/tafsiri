import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/core/constants.dart';
import 'package:tafsiri/core/locale_notifier.dart';

/// Both language pickers were in the order the languages happened to be added
/// to the app, which is no help to anyone looking for theirs (ADR-039).
void main() {
  group('compareLanguageLabels', () {
    test('files diacritics under their base letter', () {
      // The bug plain compareTo has: 'ñ' and 'ç' sit above U+00FF, so Español
      // and Français would sort after every unaccented name instead of under
      // E and F.
      final labels = ['Français', 'Nederlands', 'Español', 'Dansk']
        ..sort(compareLanguageLabels);

      expect(labels, ['Dansk', 'Español', 'Français', 'Nederlands']);
    });

    test('ignores case', () {
      expect(compareLanguageLabels('deutsch', 'Dansk'), greaterThan(0));
      expect(compareLanguageLabels('DEUTSCH', 'Deutsch'), 0);
    });

    test('groups non-Latin names after the Latin ones', () {
      final labels = ['Български', 'Svenska', 'Dansk']..sort(compareLanguageLabels);

      expect(labels, ['Dansk', 'Svenska', 'Български']);
    });
  });

  group('sortedAppLocales', () {
    test('is alphabetical and keeps every locale', () {
      final labels = sortedAppLocales.map((e) => e.$2).toList();

      expect(labels, [
        'Dansk',
        'Deutsch',
        'English (UK)',
        'Español',
        'Français',
        'Italiano',
        'Kiswahili',
        'Nederlands',
        'Norsk',
        'Polski',
        'Svenska',
        'Български',
      ]);
      expect(labels.length, supportedAppLocales.length);
    });

    test('does not disturb the source list', () {
      // The getter sorts a copy; `supportedAppLocales` is const and shared.
      final before = supportedAppLocales.map((e) => e.$1).toList();
      sortedAppLocales;

      expect(supportedAppLocales.map((e) => e.$1).toList(), before);
    });
  });

  group('sortedSttLanguageOptions', () {
    test('pins Auto to the top and sorts the rest', () {
      final options = sortedSttLanguageOptions;

      // Auto is a mode, not a language, and its label is localised — sorting it
      // by the placeholder in the constant would move it per UI language.
      expect(options.first.$1, '');
      expect(
        options.skip(1).map((e) => e.$2).toList(),
        [
          'Dansk',
          'Deutsch',
          'English',
          'Español',
          'Français',
          'Italiano',
          'Kiswahili',
          'Nederlands',
          'Norsk',
          'Polski',
          'Svenska',
          'Български',
        ],
      );
    });

    test('keeps every option', () {
      expect(sortedSttLanguageOptions.length, kSttLanguageOptions.length);
      expect(
        sortedSttLanguageOptions.map((e) => e.$1).toSet(),
        kSttLanguageOptions.map((e) => e.$1).toSet(),
      );
    });
  });
}
