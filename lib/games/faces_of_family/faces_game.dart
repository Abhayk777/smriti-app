import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../core/ability/estimator.dart';
import '../cognitive_game.dart';
import '../ghost_hand.dart';

/// Faces of My Family: face-name paired associate learning.
///
/// Domain: memory (primary), language (secondary).
/// Uses caregiver-uploaded photos. Progression:
///   3-option recognition → 2-option → free naming → relationship → last-contact
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

  /// Number of name options at a given difficulty.
  static int optionCountFor(double difficulty) {
    if (difficulty < -0.5) return 3;
    if (difficulty < 0.5) return 2;
    return 2; // higher difficulty uses free recall, but still shows 2 as fallback
  }

  /// Trial mode based on difficulty.
  static String modeFor(double difficulty) {
    if (difficulty < -0.5) return 'recognition_3';
    if (difficulty < 0.5) return 'recognition_2';
    if (difficulty < 1.5) return 'free_naming';
    if (difficulty < 2.5) return 'relationship';
    return 'last_contact';
  }

  @override
  GameItem generateItem(double difficulty, GameContent content) {
    final people = content.people.where((p) => !p.isDeceased).toList();
    if (people.isEmpty) {
      throw StateError('Faces of My Family needs at least one person');
    }

    final mode = modeFor(difficulty);
    final pool = [...people]..shuffle(_random);
    final target = pool.first;

    // Build distractor options (other people)
    final optionCount = optionCountFor(difficulty);
    final distractors = pool.skip(1).take(optionCount - 1).toList();
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
        'contentVersion': content.version,
      },
      payload: {
        'target': target,
        'options': options,
        'mode': mode,
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
