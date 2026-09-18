import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/i18n/locale_controller.dart';

import '../repo/_test_db.dart';

void main() {
  late SmritiDatabase db;

  setUp(() {
    db = newTestDb();
  });

  tearDown(() async {
    await db.close();
  });

  group('LocaleController', () {
    test('defaults to en, or custom defaultLanguage', () {
      final controller = LocaleController(db: db);
      expect(controller.currentLanguage, equals('en'));
      expect(controller.currentMeta.nativeName, equals('English'));

      final asController = LocaleController(db: db, defaultLanguage: 'as');
      expect(asController.currentLanguage, equals('as'));
      expect(asController.currentMeta.nativeName, equals('অসমীয়া'));
    });

    test('setLanguage updates in-memory language and notifies listeners', () async {
      final controller = LocaleController(db: db);
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.setLanguage('brx');

      expect(controller.currentLanguage, equals('brx'));
      expect(controller.currentMeta.nativeName, equals("बर'"));
      expect(notifyCount, equals(1));

      // Setting same language should not notify
      await controller.setLanguage('brx');
      expect(notifyCount, equals(1));
    });

    test('setLanguage persists to SQLite AppConfigs table', () async {
      final controller = LocaleController(db: db);
      await controller.setLanguage('mni');

      final saved = await db.appConfigsDao.getValue('langCode');
      expect(saved, equals('mni'));
    });

    test('init restores saved language from SQLite AppConfigs on startup', () async {
      // Pre-populate DB as if caregiver previously set Mizo
      await db.appConfigsDao.setValue('langCode', 'lus');

      final controller = LocaleController(db: db);
      expect(controller.isInitialized, isFalse);

      await controller.init();

      expect(controller.isInitialized, isTrue);
      expect(controller.currentLanguage, equals('lus'));
      expect(controller.currentMeta.nativeName, equals('Mizo'));
    });

    test('init handles empty or missing DB entry gracefully', () async {
      final controller = LocaleController(db: db);
      await controller.init();

      expect(controller.isInitialized, isTrue);
      expect(controller.currentLanguage, equals('en'));
    });
  });
}
