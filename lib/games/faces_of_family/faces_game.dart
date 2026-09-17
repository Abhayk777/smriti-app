import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../core/ability/estimator.dart';
import '../../core/progression/game_level_profiles.dart';
import '../../core/progression/level_scale.dart';
import '../cognitive_game.dart';
import '../ghost_hand.dart';

/// Faces of My Family: face-name paired associate learning.
///
/// Domain: memory (primary), language (secondary).
/// Uses caregiver-uploaded photos of the elder's own family
/// (`GameContent.people`, pulled from the caregiver's web app).
///
/// Difficulty raises the option count first, then introduces the harder
/// "how are they related" question and same-relationship distractors, and
/// finally hides the photo after a countdown (docs/PROGRESSION_PLAN.md §5.3).
///
/// Error classes:
///   - `semantic`: picked another relative (category intact, identity lost)
///   - `random`: picked a stranger
///
/// This game never touches Drift or Supabase. It generates items on request and
/// emits [TrialResult]s (AGENTS.md #10).
class FacesGame implements CognitiveGame {
  FacesGame({Random? random, GhostHandController? ghostHand})
      : _random = random ?? Random(),
        ghostHand = ghostHand ?? GhostHandController();

  final Random _random;
  final GhostHandController ghostHand;
  final _trials = StreamController<TrialResult>.broadcast();

  @override
  String get id => 'faces_of_family';

  @override
  CognitiveDomain get primaryDomain => CognitiveDomain.memory;

  @override
  PhraseKey get introPhrase => PhraseKey.facesOfFamilyIntro;

  @override
  Stream<TrialResult> get trials => _trials.stream;

  @override
  Future<void> playDemo(BuildContext context) {
    return ghostHand.play(const [
      Offset(0.5, 0.3), // look at face
      Offset(0.3, 0.7), // tap a name
    ]);
  }

  static Map<String, double> _paramsFor(double difficulty) =>
      GameLevelProfiles.facesOfFamily.paramsAt(LevelScale.difficultyToLevel(difficulty));

  /// Number of name options at a given difficulty (docs/PROGRESSION_PLAN.md §5.3).
  static int optionCountFor(double difficulty) => _paramsFor(difficulty)['optionCount']!.toInt();

  /// The typical trial mode at this difficulty. Actual selection is a random
  /// roll against `relationshipModeChance`, so a single call is descriptive
  /// rather than exactly what the next generated item will use.
  static String modeFor(double difficulty) =>
      _paramsFor(difficulty)['relationshipModeChance']! >= 0.5 ? 'relationship' : 'recognition';

  /// Seconds the photo stays visible before the elder must answer from
  /// memory; 0 means the photo never hides.
  static int revealSecondsFor(double difficulty) {
    final level = LevelScale.difficultyToLevel(difficulty);
    if (level < 11) return 0;
    return _paramsFor(difficulty)['revealSeconds']!.round();
  }

  @override
  GameItem generateItem(double difficulty, GameContent content) {
    final people = content.people.where((p) => !p.isDeceased).toList();
    if (people.isEmpty) {
      throw StateError('Faces of My Family needs at least one person');
    }

    final level = LevelScale.difficultyToLevel(difficulty);
    final params = _paramsFor(difficulty);

    final optionCount = min(params['optionCount']!.toInt(), people.length);
    final mode = _random.nextDouble() < params['relationshipModeChance']!
        ? 'relationship'
        : 'recognition';
    final revealSeconds = level < 11 ? 0 : params['revealSeconds']!.round();

    final pool = [...people]..shuffle(_random);
    final target = pool.first;
    final others = pool.skip(1).toList();

    // Above the configured chance, prefer distractors who share the target's
    // relationship (a much harder pick, e.g. two grandsons) over a free mix.
    final preferSameRelationship = _random.nextDouble() <
        params['sameRelationshipDistractorChance']!;
    final ordered = preferSameRelationship
        ? [
            ...others.where((p) => p.relationship == target.relationship),
            ...others.where((p) => p.relationship != target.relationship),
          ]
        : others;
    final distractors = ordered.take(optionCount - 1).toList();
    final options = [target, ...distractors]..shuffle(_random);

    return GameItem(
      id: 'face_${target.id}',
      difficulty: difficulty,
      context: {
        'mode': mode,
        'optionCount': options.length,
        'targetId': target.id,
        'targetName': target.name,
        'relationship': target.relationship,
        'revealSeconds': revealSeconds,
        'contentVersion': content.version,
      },
      payload: {
        'target': target,
        'options': options,
        'mode': mode,
        'revealSeconds': revealSeconds,
      },
    );
  }

  /// Called by the widget when the elder responds.
  void submit({
    required GameItem item,
    required String chosenId,
    required int initiationMs,
    required int movementMs,
  }) {
    final targetId = item.context['targetId'] as String;
    final options =
        (item.payload['options'] as List<Object?>).cast<PersonItem>();
    final correct = chosenId == targetId;

    String? errorClass;
    if (!correct) {
      final chosen = options.where((p) => p.id == chosenId).firstOrNull;
      final target = options.where((p) => p.id == targetId).firstOrNull;
      if (chosen != null && target != null) {
        // Same relationship type = semantic error (e.g., both are "nephew")
        errorClass =
            chosen.relationship == target.relationship ? 'semantic' : 'random';
      } else {
        errorClass = 'random';
      }
    }

    _trials.add(TrialResult(
      correct: correct,
      itemDifficulty: item.difficulty,
      initiationMs: initiationMs,
      movementMs: movementMs,
      chosenId: correct ? null : chosenId,
      errorClass: errorClass,
      metrics: {
        'mode': item.context['mode'],
        'optionCount': item.context['optionCount'],
      },
    ));
  }

  Future<void> dispose() => _trials.close();
}
