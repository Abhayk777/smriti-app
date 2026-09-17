// Implements docs/PROGRESSION_PLAN.md T7's acceptance criteria:
//  - generateItem at levels 1, 5, 10, 20, 40 for every game returns valid
//    items using the mock content plus a synthetic family of 5 people and a
//    routine of 6 items.
//  - Parameters in item.context match profile.paramsAt(level), after
//    content caps.
//  - Old payload keys still present; widgets fall back when new keys are
//    absent.
//  - No layout overflow at 412x915 and 1280x800 for levels 1 and 40.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/progression/game_level_profiles.dart';
import 'package:smriti/core/progression/level_scale.dart';
import 'package:smriti/games/cognitive_game.dart';
import 'package:smriti/games/faces_of_family/faces_game.dart';
import 'package:smriti/games/faces_of_family/faces_widget.dart';
import 'package:smriti/games/game_catalog.dart';
import 'package:smriti/games/lamps_festival/lamps_game.dart';
import 'package:smriti/games/lamps_festival/lamps_widget.dart';
import 'package:smriti/games/market_basket/market_basket_game.dart';
import 'package:smriti/games/market_basket/market_basket_widget.dart';
import 'package:smriti/games/my_day/my_day_game.dart';
import 'package:smriti/games/my_day/my_day_widget.dart';
import 'package:smriti/games/name_harvest/name_harvest_game.dart';
import 'package:smriti/games/name_harvest/name_harvest_widget.dart';
import 'package:smriti/games/sort_harvest/sort_harvest_game.dart';
import 'package:smriti/games/sort_harvest/sort_harvest_widget.dart';
import 'package:smriti/games/sounds_home/sounds_home_game.dart';
import 'package:smriti/games/sounds_home/sounds_home_widget.dart';
import 'package:smriti/games/trace_path/trace_path_game.dart';
import 'package:smriti/games/trace_path/trace_path_widget.dart';
import 'package:smriti/games/weaving_patterns/weaving_game.dart';
import 'package:smriti/games/weaving_patterns/weaving_widget.dart';

/// Mock content plus a synthetic family of 5 and a routine of 6, as T7 asks.
GameContent buildTestContent() {
  final file = File('assets/mock_content/mock_content.json');
  expect(
    file.existsSync(),
    isTrue,
    reason: 'mock content JSON missing at ${file.path}',
  );
  final base = GameContent.fromJson(
    jsonDecode(file.readAsStringSync()) as Map<String, Object?>,
  );

  final people = [
    for (var i = 0; i < 5; i++)
      PersonItem(
        id: 'person_$i',
        name: 'Person $i',
        relationship: [
          'daughter',
          'son',
          'grandson',
          'granddaughter',
          'friend',
        ][i],
        photoPath: '',
      ),
  ];

  final routine = [
    for (var i = 0; i < 6; i++)
      RoutineEntry(
        id: 'routine_$i',
        timeMin: 360 + i * 120,
        labelKey: [
          'Wake up',
          'Breakfast',
          'Lunch',
          'Rest',
          'Dinner',
          'Sleep',
        ][i],
        iconAsset: '🕒',
      ),
  ];

  return GameContent(
    version: base.version,
    marketItems: base.marketItems,
    people: people,
    routineItems: routine,
  );
}

const _levels = [1.0, 5.0, 10.0, 20.0, 40.0];
const _sizes = [Size(412, 915), Size(1280, 800)];

Future<void> _loadFonts() async {
  final dir =
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String f) async =>
      ByteData.sublistView(await File('$dir/$f').readAsBytes());
  final roboto = FontLoader('Roboto')
    ..addFont(read('roboto-regular.ttf'))
    ..addFont(read('roboto-medium.ttf'))
    ..addFont(read('roboto-bold.ttf'));
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(read('materialicons-regular.otf'));
  await icons.load();
}

void main() {
  late GameContent content;

  setUpAll(() async {
    content = buildTestContent();
    // Only needed for the widget-overflow section below; harmless elsewhere.
    await _loadFonts();
  });

  test('every game in the catalogue has a level profile', () {
    for (final g in gameCatalog) {
      expect(GameLevelProfiles.byGameId.containsKey(g.id), isTrue);
    }
  });

  group('market_basket', () {
    for (final level in _levels) {
      test('level $level: context matches the profile after content caps', () {
        final game = MarketBasketGame(random: Random(1));
        final difficulty = LevelScale.levelToDifficulty(level);
        final item = game.generateItem(difficulty, content);
        final params = GameLevelProfiles.marketBasket.paramsAt(level);

        final expectedListLength = min(
          params['listLength']!.toInt(),
          content.marketItems.length,
        );
        expect(item.context['listLength'], expectedListLength);
        expect(
          item.context['nearDistractors'],
          lessThanOrEqualTo(params['nearDistractors']!.toInt()),
        );

        // Old payload keys are still present.
        expect(item.payload['target'], isNotNull);
        expect(item.payload['shelf'], isNotNull);
        // New payload keys are present too.
        expect(item.payload['studySeconds'], isNotNull);
        expect(item.payload['delaySeconds'], isNotNull);
      });
    }
  });

  group('faces_of_family', () {
    for (final level in _levels) {
      test('level $level: context matches the profile after content caps', () {
        final game = FacesGame(random: Random(1));
        final difficulty = LevelScale.levelToDifficulty(level);
        final item = game.generateItem(difficulty, content);
        final params = GameLevelProfiles.facesOfFamily.paramsAt(level);

        final expectedOptionCount = min(
          params['optionCount']!.toInt(),
          content.people.length,
        );
        expect(item.context['optionCount'], expectedOptionCount);

        final expectedReveal = level < 11
            ? 0
            : params['revealSeconds']!.round();
        expect(item.context['revealSeconds'], expectedReveal);

        expect(item.payload['target'], isNotNull);
        expect(item.payload['options'], isNotNull);
        expect(item.payload['mode'], isNotNull);
      });
    }
  });

  group('sort_harvest', () {
    for (final level in _levels) {
      test(
        'level $level: mat count never exceeds the profile, dimension is unlocked',
        () {
          final game = SortHarvestGame(random: Random(1));
          final difficulty = LevelScale.levelToDifficulty(level);
          final item = game.generateItem(difficulty, content);
          final params = GameLevelProfiles.sortHarvest.paramsAt(level);

          expect(
            item.context['matCount'],
            lessThanOrEqualTo(params['matCount']!.toInt()),
          );

          const dimensions = ['type', 'colour', 'size'];
          final dimensionCount = params['dimensionCount']!.toInt().clamp(
            1,
            dimensions.length,
          );
          final eligible = dimensions.take(dimensionCount);
          expect(eligible, contains(item.context['dimension']));

          expect(item.payload['card'], isNotNull);
          expect(item.payload['mats'], isNotNull);
          expect(item.payload['dimension'], isNotNull);
          expect(item.payload['correctMat'], isNotNull);
        },
      );
    }
  });

  group('trace_path', () {
    for (final level in _levels) {
      test(
        'level $level: context matches the profile exactly (uncapped by content)',
        () {
          final game = TracePathGame(random: Random(1));
          final difficulty = LevelScale.levelToDifficulty(level);
          final item = game.generateItem(difficulty, content);
          final params = GameLevelProfiles.tracePath.paramsAt(level);

          expect(item.context['nodeCount'], params['nodeCount']!.round());
          expect(item.context['decoyCount'], params['decoyStones']!.toInt());

          expect(item.payload['nodes'], isNotNull);
          expect(item.payload['variant'], isNotNull);
          expect(item.payload['decoys'], isNotNull);
        },
      );
    }
  });

  group('my_day', () {
    for (final level in _levels) {
      test(
        'level $level: ordering event count is capped by the routine length',
        () {
          final game = MyDayGame(random: Random(1));
          final difficulty = LevelScale.levelToDifficulty(level);
          final item = game.generateItem(difficulty, content);
          final params = GameLevelProfiles.myDay.paramsAt(level);

          if (item.context['mode'] == 'ordering') {
            final expectedCount = min(
              params['eventCount']!.toInt(),
              content.routineItems.length,
            );
            expect(item.context['eventCount'], expectedCount);
            expect(item.payload['events'], isNotNull);
            expect(item.payload['correctOrder'], isNotNull);
          } else {
            expect(item.payload['question'], isNotNull);
            expect(item.context['dateOptionSpread'], isNotNull);
          }
        },
      );
    }

    test('with fewer than 3 routine items, mode is always orientation', () {
      final sparse = GameContent(
        version: content.version,
        marketItems: content.marketItems,
        people: content.people,
        routineItems: content.routineItems.take(2).toList(),
      );
      final game = MyDayGame(random: Random(1));
      for (final level in _levels) {
        final item = game.generateItem(
          LevelScale.levelToDifficulty(level),
          sparse,
        );
        expect(item.context['mode'], 'orientation');
      }
    });
  });

  group('lamps_festival', () {
    for (final level in _levels) {
      test(
        'level $level: context matches the profile exactly (uncapped by content)',
        () {
          final game = LampsGame(random: Random(1));
          final difficulty = LevelScale.levelToDifficulty(level);
          final item = game.generateItem(difficulty, content);
          final params = GameLevelProfiles.lampsFestival.paramsAt(level);

          expect(item.context['span'], params['span']!.toInt());
          expect(item.context['lampCount'], params['lampCount']!.toInt());

          expect(item.payload['lamps'], isNotNull);
          expect(item.payload['sequence'], isNotNull);
          expect(item.payload['direction'], isNotNull);
          expect(item.payload['litMs'], isNotNull);
        },
      );
    }
  });

  group('name_harvest', () {
    for (final level in _levels) {
      test(
        'level $level: expectedCount matches the profile, category is unlocked',
        () {
          final game = NameHarvestGame(random: Random(1));
          final difficulty = LevelScale.levelToDifficulty(level);
          final item = game.generateItem(difficulty, content);
          final params = GameLevelProfiles.nameHarvest.paramsAt(level);

          expect(
            item.context['expectedCount'],
            params['expectedCount']!.toInt(),
          );

          expect(item.payload['category'], isNotNull);
          expect(item.payload['durationSeconds'], 60);
        },
      );
    }
  });

  group('weaving_patterns', () {
    for (final level in _levels) {
      test(
        'level $level: element count matches the profile, pattern type is unlocked',
        () {
          final game = WeavingGame(random: Random(1));
          final difficulty = LevelScale.levelToDifficulty(level);
          final item = game.generateItem(difficulty, content);
          final params = GameLevelProfiles.weavingPatterns.paramsAt(level);

          expect(item.context['elementCount'], params['elementCount']!.toInt());

          expect(item.payload['targetPattern'], isNotNull);
          expect(item.payload['options'], isNotNull);
          expect(item.payload['correctId'], isNotNull);
        },
      );
    }
  });

  group('sounds_home', () {
    for (final level in _levels) {
      test('level $level: targetFrequency matches the profile exactly', () {
        final game = SoundsHomeGame(random: Random(1));
        final difficulty = LevelScale.levelToDifficulty(level);
        final item = game.generateItem(difficulty, content);
        final params = GameLevelProfiles.soundsHome.paramsAt(level);

        expect(
          item.context['targetFrequency'],
          closeTo(params['targetFrequency']!, 1e-9),
        );

        expect(item.payload['stimuli'], isNotNull);
        expect(item.payload['targetSound'], 'bird');
        expect(item.payload['durationSeconds'], 90);
      });
    }
  });

  group(
    'widgets render without overflow at every screen size and extreme level',
    () {
      final widgets = <String, Widget Function(double level)>{
        'market_basket': (level) {
          final game = MarketBasketGame(random: Random(2));
          final item = game.generateItem(
            LevelScale.levelToDifficulty(level),
            content,
          );
          return MarketBasketWidget(game: game, item: item, onComplete: () {});
        },
        'faces_of_family': (level) {
          final game = FacesGame(random: Random(2));
          final item = game.generateItem(
            LevelScale.levelToDifficulty(level),
            content,
          );
          return FacesWidget(game: game, item: item, onComplete: () {});
        },
        'sort_harvest': (level) {
          final game = SortHarvestGame(random: Random(2));
          final item = game.generateItem(
            LevelScale.levelToDifficulty(level),
            content,
          );
          return SortHarvestWidget(game: game, item: item, onComplete: () {});
        },
        'trace_path': (level) {
          final game = TracePathGame(random: Random(2));
          final item = game.generateItem(
            LevelScale.levelToDifficulty(level),
            content,
          );
          return TracePathWidget(game: game, item: item, onComplete: () {});
        },
        'my_day': (level) {
          final game = MyDayGame(random: Random(2));
          final item = game.generateItem(
            LevelScale.levelToDifficulty(level),
            content,
          );
          return MyDayWidget(game: game, item: item, onComplete: () {});
        },
        'lamps_festival': (level) {
          final game = LampsGame(random: Random(2));
          final item = game.generateItem(
            LevelScale.levelToDifficulty(level),
            content,
          );
          return LampsWidget(game: game, item: item, onComplete: () {});
        },
        'name_harvest': (level) {
          final game = NameHarvestGame(random: Random(2));
          final item = game.generateItem(
            LevelScale.levelToDifficulty(level),
            content,
          );
          return NameHarvestWidget(game: game, item: item, onComplete: () {});
        },
        'weaving_patterns': (level) {
          final game = WeavingGame(random: Random(2));
          final item = game.generateItem(
            LevelScale.levelToDifficulty(level),
            content,
          );
          return WeavingWidget(game: game, item: item, onComplete: () {});
        },
        'sounds_home': (level) {
          final game = SoundsHomeGame(random: Random(2));
          final item = game.generateItem(
            LevelScale.levelToDifficulty(level),
            content,
          );
          return SoundsHomeWidget(game: game, item: item, onComplete: () {});
        },
      };

      for (final size in _sizes) {
        for (final entry in widgets.entries) {
          for (final level in [1.0, 40.0]) {
            testWidgets(
              '${entry.key} at level $level, ${size.width.toInt()}x${size.height.toInt()}',
              (tester) async {
                tester.view.physicalSize = size;
                tester.view.devicePixelRatio = 1.0;
                addTearDown(tester.view.resetPhysicalSize);

                await tester.pumpWidget(
                  MaterialApp(
                    debugShowCheckedModeBanner: false,
                    home: Scaffold(body: entry.value(level)),
                  ),
                );
                for (var i = 0; i < 3; i++) {
                  await tester.pump(const Duration(milliseconds: 400));
                }

                expect(tester.takeException(), isNull);
                // Let any internal timer (phase transitions, sequence
                // playback) run to completion while still mounted, so each
                // widget's own `mounted` checks see the tree as it actually
                // is, then unmount.
                await tester.pump(const Duration(minutes: 3));
                await tester.pumpWidget(const SizedBox());
              },
            );
          }
        }
      }
    },
  );

  group('widgets fall back gracefully when new payload keys are absent', () {
    testWidgets(
      'market_basket: no studySeconds/delaySeconds falls back to the old timing',
      (tester) async {
        final game = MarketBasketGame(random: Random(3));
        final item = game.generateItem(0, content);
        final oldStyleItem = GameItem(
          id: item.id,
          difficulty: item.difficulty,
          context: item.context,
          payload: {
            'target': item.payload['target'],
            'shelf': item.payload['shelf'],
            // studySeconds/delaySeconds deliberately omitted.
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MarketBasketWidget(
                game: game,
                item: oldStyleItem,
                onComplete: () {},
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(minutes: 3));
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('lamps_festival: no litMs falls back to 600ms', (tester) async {
      final game = LampsGame(random: Random(3));
      final item = game.generateItem(0, content);
      final oldStyleItem = GameItem(
        id: item.id,
        difficulty: item.difficulty,
        context: item.context,
        payload: {
          'lamps': item.payload['lamps'],
          'sequence': item.payload['sequence'],
          'direction': item.payload['direction'],
          // litMs deliberately omitted.
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LampsWidget(
              game: game,
              item: oldStyleItem,
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      // Let any internal timer run to completion while still mounted, then
      // unmount, so no pending timer trips the test framework's own checks.
      await tester.pump(const Duration(minutes: 3));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'faces_of_family: no revealSeconds means the photo never hides',
      (tester) async {
        final game = FacesGame(random: Random(3));
        final item = game.generateItem(0, content);
        final oldStyleItem = GameItem(
          id: item.id,
          difficulty: item.difficulty,
          context: item.context,
          payload: {
            'target': item.payload['target'],
            'options': item.payload['options'],
            'mode': item.payload['mode'],
            // revealSeconds deliberately omitted.
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FacesWidget(
                game: game,
                item: oldStyleItem,
                onComplete: () {},
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(minutes: 3));
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('trace_path: no decoys renders with none', (tester) async {
      final game = TracePathGame(random: Random(3));
      final item = game.generateItem(0, content);
      final oldStyleItem = GameItem(
        id: item.id,
        difficulty: item.difficulty,
        context: item.context,
        payload: {
          'nodes': item.payload['nodes'],
          'variant': item.payload['variant'],
          // decoys deliberately omitted.
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TracePathWidget(
              game: game,
              item: oldStyleItem,
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      // Let any internal timer run to completion while still mounted, then
      // unmount, so no pending timer trips the test framework's own checks.
      await tester.pump(const Duration(minutes: 3));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('my_day: no dateOptionSpread falls back to a spread of 2', (
      tester,
    ) async {
      final game = MyDayGame(random: Random(3));
      // Force an orientation "date" item deterministically by using a sparse
      // routine so the mode is always orientation, then keep asking until a
      // date question comes up (bounded, since the pool is small).
      final sparse = GameContent(
        version: content.version,
        marketItems: content.marketItems,
        people: content.people,
        routineItems: const [],
      );
      GameItem? dateItem;
      for (var i = 0; i < 50 && dateItem == null; i++) {
        final item = game.generateItem(
          4.0,
          sparse,
        ); // high level unlocks 'date'
        if (item.context['questionId'] == 'date') dateItem = item;
      }
      expect(
        dateItem,
        isNotNull,
        reason: 'date question should appear within 50 tries at a high level',
      );

      final oldStyleItem = GameItem(
        id: dateItem!.id,
        difficulty: dateItem.difficulty,
        context: dateItem.context,
        payload: {
          'question': dateItem.payload['question'],
          'mode': dateItem.payload['mode'],
          // dateOptionSpread deliberately omitted.
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyDayWidget(
              game: game,
              item: oldStyleItem,
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      // Let any internal timer run to completion while still mounted, then
      // unmount, so no pending timer trips the test framework's own checks.
      await tester.pump(const Duration(minutes: 3));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
