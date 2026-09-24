// The redesign, on a page, without a phone.
//
// Renders each elder-facing screen to a PNG under build/render/, so the work
// can be looked at while no device is attached. Run it with:
//
//   flutter test tool/render/render_screens.dart
//
// Text comes out as blocks, because the test renderer has no real fonts. That
// is fine: this is for layout, colour, weight and spacing, not for reading.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/app_database.dart';
import 'package:smriti/core/db/database.dart';
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

import '../../test/core/repo/_test_db.dart';

const _phone = Size(412, 915);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SmritiDatabase db;

  setUpAll(() async {
    // The screens reach for platform plugins that do not exist in a test
    // renderer. Answering them keeps a missing plugin from interrupting the
    // shot half way through.
    for (final channel in const [
      'dev.fluttercommunity.plus/connectivity',
      'plugins.flutter.io/path_provider',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), (call) async => null);
    }

    db = newTestDb();
    appDatabase = db;

    // Enough content that the screens show something rather than their empty
    // states. Times are minutes from midnight.
    await db.into(db.medications).insert(MedicationsCompanion.insert(
          id: 'med_1',
          name: 'Metformin 500mg',
          dose: '1 tablet after food',
          chosenTimeMin: 540,
          daysOfWeek: '1,2,3,4,5,6,7',
          windowStartMin: 480,
          windowEndMin: 600,
        ));
    await db.into(db.medications).insert(MedicationsCompanion.insert(
          id: 'med_2',
          name: 'Amlodipine 5mg',
          dose: '1 tablet at night',
          chosenTimeMin: 1200,
          daysOfWeek: '1,2,3,4,5,6,7',
          windowStartMin: 1140,
          windowEndMin: 1260,
        ));
  });

  tearDownAll(() async => db.close());

  Future<void> shoot(WidgetTester tester, String name, Widget screen) async {
    final key = GlobalKey();
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SmritiTheme.light(),
        builder: (context, child) => MediaQuery(
          // Stillness settles every entrance in one frame, so the shot shows
          // the screen at rest rather than mid-rise.
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: RepaintBoundary(
            key: key,
            child: LivingBackground(child: child ?? const SizedBox.shrink()),
          ),
        ),
        home: screen,
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.6);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/render').createSync(recursive: true);
    File('build/render/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    // ignore: avoid_print
    print('wrote build/render/$name.png');

    // Down inside the test, so the database's cleanup timer fires here rather
    // than being left pending after the tree is gone.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    while (tester.takeException() != null) {}
  }

  final screens = <String, Widget Function()>{
    '10_home': () => const HomeScreen(),
    '11_game_select': () => const GameSelectScreen(),
    '12_medicine': () => const MedicineScreen(),
    '13_my_day': () => const MyDayScreen(),
    '14_family': () => const FamilyScreen(),
    '15_photos': () => const PhotosScreen(),
    '16_music': () => const MusicScreen(),
    '17_voice_memo': () => const VoiceMemoScreen(),
  };

  for (final s in screens.entries) {
    testWidgets(s.key, (tester) async {
      await shoot(tester, s.key, s.value());
    });
  }
}
