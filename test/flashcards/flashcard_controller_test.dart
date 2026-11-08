import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tafsiri/core/constants.dart';
import 'package:tafsiri/core/database/dao_provider.dart';
import 'package:tafsiri/core/database/db_helper.dart';
import 'package:tafsiri/core/database/review_dao.dart';
import 'package:tafsiri/core/database/sqflite_desktop.dart';
import 'package:tafsiri/core/database/translation_dao.dart';
import 'package:tafsiri/core/services/ai_service.dart';
import 'package:tafsiri/core/services/ai_service_factory.dart';
import 'package:tafsiri/features/flashcards/flashcard.dart';
import 'package:tafsiri/features/flashcards/flashcard_controller.dart';
import 'package:tafsiri/features/flashcards/scheduler.dart';
import 'package:tafsiri/shared/models/translation_entry.dart';
import '../translator/mock_ai_service.mocks.dart';

final _now = DateTime(2026, 11, 8, 9);

void main() {
  late Database db;
  late TranslationDao entries;
  late ReviewDao reviews;
  late MockAiService ai;

  setUp(() async {
    databaseFactory = createDesktopDatabaseFactory();
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DbHelper.schemaVersion,
        onCreate: (db, _) => DbHelper.createSchema(db),
      ),
    );
    entries = TranslationDao(db);
    reviews = ReviewDao(db);
    ai = MockAiService();
  });
  tearDown(() => db.close());

  Future<int> favourite(String de, String sw) => entries.insert(TranslationEntry(
        sourceText: de,
        resultText: sw,
        sourceLang: 'de',
        targetLang: 'Swahili',
        aiProvider: kProviderClaude,
        isFavourite: true,
        createdAt: DateTime.utc(2026, 11, 1),
      ));

  void aiSays(String raw) => when(ai.complete(
        system: anyNamed('system'),
        user: anyNamed('user'),
        apiKey: anyNamed('apiKey'),
        model: anyNamed('model'),
      )).thenAnswer((_) async => raw);

  Future<ProviderContainer> start({String key = 'sk-test'}) async {
    SharedPreferences.setMockInitialValues({
      kPrefApiKeyClaude: key,
      kPrefActiveProvider: kProviderClaude,
      kPrefTargetLanguage: 'Swahili',
      kPrefAltLanguage: 'German',
    });
    final c = ProviderContainer(overrides: [
      translationDaoProvider.overrideWith((_) async => entries),
      reviewDaoProvider.overrideWith((_) async => reviews),
      aiServiceProvider.overrideWithValue(ai),
      learnClockProvider.overrideWithValue(() => _now),
    ]);
    addTearDown(c.dispose);
    // Keep the auto-disposed session alive for the test.
    c.listen(learnProvider, (_, __) {});
    // The database answers from another isolate; wait for the session.
    for (var i = 0; i < 200 && c.read(learnProvider).phase == LearnPhase.loading; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return c;
  }

  LearnController ctl(ProviderContainer c) => c.read(learnProvider.notifier);
  LearnState st(ProviderContainer c) => c.read(learnProvider);

  test('a favourite becomes two cards, producing first', () async {
    await favourite('das ist gesund', 'hii ni yenye afya');
    final c = await start();

    expect(st(c).phase, LearnPhase.asking);
    expect(st(c).total, 2);
    expect(st(c).card!.direction, CardDirection.produce);
    expect(st(c).card!.prompt, 'das ist gesund');
    expect(st(c).answerLanguage, 'Swahili');
  });

  test('no favourites: nothing to learn', () async {
    final c = await start();
    expect(st(c).phase, LearnPhase.nothingDue);
  });

  test('the AI verdict is suggested, the user may change it, it is saved',
      () async {
    final id = await favourite('das ist gesund', 'hii ni yenye afya');
    aiSays('VERDICT:almost\nFEEDBACK:\n- afia → afya: Rechtschreibung');
    final c = await start();

    await ctl(c).submit('hii ni yenye afia');
    expect(st(c).phase, LearnPhase.result);
    expect(st(c).grade, Grade.almost);
    expect(st(c).verdict!.feedback, contains('afya'));

    ctl(c).setGrade(Grade.correct);
    await ctl(c).next();

    final saved = (await reviews.getAll())[(id, CardDirection.produce)]!;
    expect(saved.repetitions, 1);
    expect(saved.ease, kStartEase, reason: 'graded correct, not almost');
    expect(st(c).counts[Grade.correct], 1);
    expect(st(c).card!.direction, CardDirection.recall);
  });

  test('a wrong card comes back at the end of the session', () async {
    await favourite('das ist gesund', 'hii ni yenye afya');
    final c = await start();

    await ctl(c).submit(''); // I don't know
    expect(st(c).grade, Grade.wrong);
    verifyNever(ai.complete(
      system: anyNamed('system'),
      user: anyNamed('user'),
      apiKey: anyNamed('apiKey'),
      model: anyNamed('model'),
    ));
    await ctl(c).next();
    expect(st(c).total, 3);

    aiSays('VERDICT:correct\nFEEDBACK:');
    await ctl(c).submit('das ist gesund'); // recall card
    await ctl(c).next();

    expect(st(c).card!.direction, CardDirection.produce, reason: 'again');
    expect(st(c).position, 3);
  });

  test('without a key the user grades alone', () async {
    await favourite('das ist gesund', 'hii ni yenye afya');
    final c = await start(key: '');

    await ctl(c).submit('hii ni nzuri');

    expect(st(c).phase, LearnPhase.result);
    expect(st(c).aiUnavailable, isTrue);
    expect(st(c).grade, isNull);
    await ctl(c).next(); // nothing picked: does not move on
    expect(st(c).position, 1);
  });

  test('an API error falls back to grading alone', () async {
    await favourite('das ist gesund', 'hii ni yenye afya');
    when(ai.complete(
      system: anyNamed('system'),
      user: anyNamed('user'),
      apiKey: anyNamed('apiKey'),
      model: anyNamed('model'),
    )).thenThrow(const AiApiException(500, 'boom'));
    final c = await start();

    await ctl(c).submit('hii ni nzuri');

    expect(st(c).aiUnavailable, isTrue);
  });

  test('the session ends with a summary', () async {
    await favourite('das ist gesund', 'hii ni yenye afya');
    aiSays('VERDICT:correct\nFEEDBACK:');
    final c = await start();

    for (var i = 0; i < 2; i++) {
      await ctl(c).submit('irgendwas');
      await ctl(c).next();
    }

    expect(st(c).phase, LearnPhase.done);
    expect(st(c).counts[Grade.correct], 2);
  });
}
