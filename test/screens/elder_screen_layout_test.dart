// The layout half of docs/UI_REDESIGN_PLAN.md §10.
//
// Every elder-facing screen has to survive the two sizes an elder is most
// likely to hand it: a small phone, and a normal phone with the system font
// turned all the way up. A RenderFlex overflow is a real failure here, not a
// cosmetic one, because the thing that gets cut off is usually the button.
//
// It listens for overflow specifically rather than for any exception at all:
// these screens open their own database streams, and tearing one down inside
// a widget test raises noise that has nothing to do with how the page fits.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/app_database.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/i18n/locale_controller.dart';
import 'package:smriti/screens/family_screen.dart';
import 'package:smriti/screens/game_select_screen.dart';
import 'package:smriti/screens/home_screen.dart';
import 'package:smriti/screens/medicine_screen.dart';
import 'package:smriti/screens/music_screen.dart';
import 'package:smriti/screens/my_day_screen.dart';
import 'package:smriti/screens/photos_screen.dart';
import 'package:smriti/screens/voice_memo_screen.dart';
import 'package:smriti/ui/smriti_ui.dart';
import 'package:smriti/ui/textures.dart';

import '../core/repo/_test_db.dart';

/// A small phone, and a normal phone with the largest system font.
const _sizes = <String, (Size, double)>{
  'a small phone': (Size(320, 560), 1.0),
  'the largest system font': (Size(412, 915), 1.5),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // One database for the file. Building a fresh one per test made drift warn
  // about several live databases and race its own cleanup.
  late SmritiDatabase db;

  setUpAll(() {
    db = newTestDb();
    appDatabase = db;
  });

  tearDownAll(() async => db.close());

  // The database is left open on purpose. These screens start work in
  // initState that outlives the frame the test needs, and closing underneath
  // it only produces noise. The process ends with the file.
  tearDown(() async {
    await LocaleController.instance.setLanguage('en');
  });

  final screens = <String, Widget Function()>{
    'home': () => const HomeScreen(),
    'medicine': () => const MedicineScreen(),
    'my day': () => const MyDayScreen(),
    'family': () => const FamilyScreen(),
    'photos': () => const PhotosScreen(),
    'music': () => const MusicScreen(),
    'voice memo': () => const VoiceMemoScreen(),
    'game select': () => const GameSelectScreen(),
  };

  for (final screen in screens.entries) {
    for (final size in _sizes.entries) {
      testWidgets('${screen.key} fits on ${size.key}', (tester) async {
        // Overflow is collected; everything else is swallowed here. These
        // screens open database streams whose teardown raises errors that say
        // nothing about how the page fits.
        final overflows = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          final text = details.exceptionAsString();
          if (text.contains('overflowed')) overflows.add(text.split('\n').first);
        };
        addTearDown(() => FlutterError.onError = previous);

        tester.view.physicalSize = size.value.$1;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: SmritiTheme.light(),
            builder: (context, child) => MediaQuery(
              // Stillness, so the entrances settle in one frame and the
              // page's drift does not keep the binding busy.
              data: MediaQuery.of(context).copyWith(
                disableAnimations: true,
                textScaler: TextScaler.linear(size.value.$2),
              ),
              child: LivingBackground(child: child ?? const SizedBox.shrink()),
            ),
            home: screen.value(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));

        // Take the screen down inside the test and let the database's own
        // cleanup timer fire, rather than leaving it pending for the
        // framework to complain about after the tree is gone.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(Duration.zero);

        // onError goes back before the check, or a failure here is reported
        // as a stray override rather than as the overflow it is.
        FlutterError.onError = previous;
        while (tester.takeException() != null) {}

        expect(
          overflows,
          isEmpty,
          reason: '${screen.key} overflowed on ${size.key}',
        );
      });
    }
  }
}
