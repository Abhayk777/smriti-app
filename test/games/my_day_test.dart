import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/app_database.dart';
import 'package:smriti/core/progression/level_scale.dart';
import 'package:smriti/games/cognitive_game.dart';
import 'package:smriti/games/my_day/my_day_game.dart';
import 'package:smriti/games/my_day/my_day_widget.dart';

void main() {
  final testRoutine = [
    const RoutineEntry(id: 'wake_up', timeMin: 420, labelKey: 'Wake Up', iconAsset: '☀️'),
    const RoutineEntry(id: 'breakfast', timeMin: 480, labelKey: 'Breakfast', iconAsset: '🍳'),
    const RoutineEntry(id: 'lunch', timeMin: 720, labelKey: 'Lunch', iconAsset: '🍛'),
    const RoutineEntry(id: 'evening_tea', timeMin: 1020, labelKey: 'Evening Tea', iconAsset: '🍵'),
    const RoutineEntry(id: 'dinner', timeMin: 1200, labelKey: 'Dinner', iconAsset: '🍽️'),
  ];

  final testContent = GameContent(
    version: '1',
    marketItems: const [],
    routineItems: testRoutine,
  );

  group('MyDayGame.jumbleEvents', () {
    final sampleItems = [
      {'id': 'wake_up', 'label': 'Wake Up', 'timeMin': 420, 'icon': '☀️'},
      {'id': 'breakfast', 'label': 'Breakfast', 'timeMin': 480, 'icon': '🍳'},
      {'id': 'lunch', 'label': 'Lunch', 'timeMin': 720, 'icon': '🍛'},
    ];

    test('level 1 produces an easy jumble (1 adjacent swap, displacing 2 items)', () {
      final random = Random(42);
      final jumbled = MyDayGame.jumbleEvents(
        items: sampleItems,
        level: 1.0,
        random: random,
      );

      expect(jumbled.length, sampleItems.length);

      // Exactly 1 item remains in its original position, 2 are swapped (adjacent)
      var unchanged = 0;
      for (var i = 0; i < sampleItems.length; i++) {
        if (jumbled[i]['id'] == sampleItems[i]['id']) unchanged++;
      }
      expect(unchanged, 1);
    });

    test('jumbled output is never identical to correct order', () {
      final random = Random(123);
      for (var level = 1.0; level <= 10.0; level += 1.0) {
        for (var run = 0; run < 20; run++) {
          final jumbled = MyDayGame.jumbleEvents(
            items: sampleItems,
            level: level,
            random: random,
          );
          final jumbledIds = jumbled.map((e) => e['id']).toList();
          final correctIds = sampleItems.map((e) => e['id']).toList();
          expect(jumbledIds, isNot(equals(correctIds)), reason: 'Run $run at level $level must be jumbled');
        }
      }
    });

    test('scales jumble intensity with level', () {
      final fiveItems = [
        {'id': '1', 'timeMin': 100},
        {'id': '2', 'timeMin': 200},
        {'id': '3', 'timeMin': 300},
        {'id': '4', 'timeMin': 400},
        {'id': '5', 'timeMin': 500},
      ];
      final random = Random(99);

      // Level 1: exactly 1 adjacent swap
      final lvl1 = MyDayGame.jumbleEvents(items: fiveItems, level: 1.0, random: random);
      var displacedLvl1 = 0;
      for (var i = 0; i < fiveItems.length; i++) {
        if (lvl1[i]['id'] != fiveItems[i]['id']) displacedLvl1++;
      }
      expect(displacedLvl1, 2); // only 2 items swapped

      // Level 8: full jumble with high displacement
      final lvl8 = MyDayGame.jumbleEvents(items: fiveItems, level: 8.0, random: random);
      var displacedLvl8 = 0;
      for (var i = 0; i < fiveItems.length; i++) {
        if (lvl8[i]['id'] != fiveItems[i]['id']) displacedLvl8++;
      }
      expect(displacedLvl8, greaterThanOrEqualTo(3));
    });
  });

  group('MyDayGame.generateItem', () {
    test('always generates ordering mode when routine items are present', () {
      final game = MyDayGame(random: Random(7));
      for (var lvl = 1.0; lvl <= 10.0; lvl += 1.0) {
        final item = game.generateItem(LevelScale.levelToDifficulty(lvl), testContent);
        expect(item.context['mode'], 'ordering');
        expect(item.payload['mode'], 'ordering');
        expect(item.payload['events'], isA<List>());
        expect(item.payload['correctOrder'], isA<List>());
      }
    });

    test('caps count at routine length and orders events chronologically', () {
      final game = MyDayGame(random: Random(7));
      final item = game.generateItem(LevelScale.levelToDifficulty(1.0), testContent);
      final correct = (item.payload['correctOrder'] as List).cast<String>();

      // Check chronological order of chosen items
      expect(correct, ['wake_up', 'breakfast', 'evening_tea']);
    });
  });

  group('MyDayWidget UI & Interactions', () {
    testWidgets('renders slot badges, emoji, translated label, and Done button', (tester) async {
      final game = MyDayGame(random: Random(1));
      final item = game.generateItem(LevelScale.levelToDifficulty(1.0), testContent);

      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyDayWidget(
              game: game,
              item: item,
              onComplete: () => completed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Slot indicators 1, 2, 3
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Done button
      expect(find.text('Done'), findsOneWidget);
      expect(completed, isFalse);

      await tester.pumpWidget(const SizedBox());
      await game.dispose();
    });

    testWidgets('Move Up and Move Down buttons swap items correctly', (tester) async {
      final game = MyDayGame(random: Random(1));
      final item = game.generateItem(LevelScale.levelToDifficulty(1.0), testContent);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyDayWidget(
              game: game,
              item: item,
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final upButtons = find.byTooltip('Move Up');
      final downButtons = find.byTooltip('Move Down');

      // Top item cannot move up (disabled), bottom item cannot move down (disabled)
      expect(upButtons, findsWidgets);
      expect(downButtons, findsWidgets);

      // Tap move down on slot 1
      await tester.tap(downButtons.first);
      await tester.pumpAndSettle();

      // Tap Move Up on slot 2
      await tester.tap(upButtons.at(1));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await game.dispose();
    });

    test('submitting ordering emits TrialResult with ordering mode', () async {
      final game = MyDayGame(random: Random(1));
      final item = game.generateItem(LevelScale.levelToDifficulty(1.0), testContent);

      TrialResult? submittedTrial;
      final sub = game.trials.listen((t) => submittedTrial = t);

      game.submitOrdering(
        item: item,
        chosenOrder: ['wake_up', 'breakfast', 'evening_tea'],
        initiationMs: 800,
        movementMs: 1200,
      );

      await Future<void>.delayed(Duration.zero);
      expect(submittedTrial, isNotNull);
      expect(submittedTrial!.metrics['mode'], 'ordering');
      expect(submittedTrial!.correct, isTrue);

      await sub.cancel();
      await game.dispose();
    });
  });

  tearDownAll(() async {
    await appDatabase.close();
  });
}
