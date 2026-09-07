import 'package:flutter/widgets.dart';

import '../core/ability/estimator.dart';

/// Keys for pre-recorded voice phrases. The voice layer (task A16) maps these
/// to audio files in the active language pack; nothing here ever synthesises or
/// displays raw text to the elder.
enum PhraseKey {
  sessionStart,
  sessionEnd,
  wellDone,
  tryAnother,
  // Game intros
  marketBasketIntro,
  facesOfFamilyIntro,
  sortHarvestIntro,
  tracePathIntro,
  myDayIntro,
  lampsFestivalIntro,
  nameHarvestIntro,
  weavingPatternsIntro,
  soundsHomeIntro,
}

/// One playable item generated for a trial.
///
/// [context] is serialised into `TrialEvents.trialContext`, so it must hold
/// whatever the report pipeline needs to reconstruct what the elder was shown
/// (list length, distractor count, and so on). [payload] carries game-specific
/// data for the widget layer and is never persisted directly.
class GameItem {
  const GameItem({
    required this.id,
    required this.difficulty,
    this.context = const {},
    this.payload = const {},
  });

  final String id;
  final double difficulty;
  final Map<String, Object?> context;
  final Map<String, Object?> payload;
}

/// What a game emits when the elder finishes a trial.
///
/// Exactly the fields listed in APP-BUILD-SPEC.md §11. Games never supply
/// `itemId`, `trialIndex`, `hintLevel` or any timestamp — the session runner
/// owns those, because it owns the session.
class TrialResult {
  const TrialResult({
    required this.correct,
    required this.itemDifficulty,
    required this.initiationMs,
    required this.movementMs,
    this.chosenId,
    this.errorClass,
    this.metrics = const {},
  });

  /// Time from item presented to first touch — the decision component.
  final int initiationMs;

  /// Time from first touch to committed answer — the motor component.
  final int movementMs;

  final bool correct;
  final double itemDifficulty;

  /// What the elder actually chose when [correct] is false.
  final String? chosenId;

  /// Coarse category of the mistake, for the report pipeline.
  final String? errorClass;

  final Map<String, Object?> metrics;
}

// ---------------------------------------------------------------------------
// Content models for all games
// ---------------------------------------------------------------------------

/// A single purchasable thing on the market shelf.
class MarketItem {
  const MarketItem({
    required this.id,
    required this.labelKey,
    required this.iconAsset,
    required this.category,
  });

  factory MarketItem.fromJson(Map<String, Object?> json) => MarketItem(
        id: json['id'] as String,
        labelKey: json['labelKey'] as String,
        iconAsset: json['iconAsset'] as String,
        category: json['category'] as String,
      );

  final String id;
  final String labelKey;
  final String iconAsset;

  /// Used to classify a wrong pick as semantically near or far.
  final String category;
}

/// A person from the elder's family, for the Faces of My Family game.
class PersonItem {
  const PersonItem({
    required this.id,
    required this.name,
    required this.relationship,
    required this.photoPath,
    this.voicePath,
    this.memoryPrompt,
    this.isDeceased = false,
  });

  factory PersonItem.fromJson(Map<String, Object?> json) => PersonItem(
        id: json['id'] as String,
        name: json['name'] as String,
        relationship: json['relationship'] as String,
        photoPath: json['photoPath'] as String? ?? '',
        voicePath: json['voicePath'] as String?,
        memoryPrompt: json['memoryPrompt'] as String?,
        isDeceased: json['isDeceased'] as bool? ?? false,
      );

  final String id;
  final String name;
  final String relationship;
  final String photoPath;
  final String? voicePath;
  final String? memoryPrompt;
  final bool isDeceased;
}

/// A routine activity for the My Day game.
class RoutineEntry {
  const RoutineEntry({
    required this.id,
    required this.timeMin,
    required this.labelKey,
    required this.iconAsset,
  });

  factory RoutineEntry.fromJson(Map<String, Object?> json) => RoutineEntry(
        id: json['id'] as String,
        timeMin: json['timeMin'] as int,
        labelKey: json['labelKey'] as String,
        iconAsset: json['iconAsset'] as String,
      );

  final String id;
  final int timeMin; // minutes from midnight
  final String labelKey;
  final String iconAsset;
}

/// Content a game draws its items from. Today this is loaded from the mock
/// content JSON; from task A09 onward `ContentPuller` populates the same shape
/// from Drift.
class GameContent {
  const GameContent({
    required this.version,
    required this.marketItems,
    this.people = const [],
    this.routineItems = const [],
  });

  factory GameContent.fromJson(Map<String, Object?> json) {
    final items = (json['marketItems'] as List<Object?>? ?? const [])
        .cast<Map<String, Object?>>()
        .map(MarketItem.fromJson)
        .toList(growable: false);

    final people = (json['people'] as List<Object?>? ?? const [])
        .cast<Map<String, Object?>>()
        .map(PersonItem.fromJson)
        .toList(growable: false);

    final routines = (json['routineItems'] as List<Object?>? ?? const [])
        .cast<Map<String, Object?>>()
        .map(RoutineEntry.fromJson)
        .toList(growable: false);

    return GameContent(
      version: json['version'] as String? ?? 'unknown',
      marketItems: items,
      people: people,
      routineItems: routines,
    );
  }

  final String version;
  final List<MarketItem> marketItems;
  final List<PersonItem> people;
  final List<RoutineEntry> routineItems;
}

/// The contract every game implements, per APP-BUILD-SPEC.md §11.
///
/// Games never touch Drift or Supabase (AGENTS.md non-negotiable #10). They
/// generate items on request and emit [TrialResult]s; the session runner owns
/// all persistence.
abstract class CognitiveGame {
  String get id;
  CognitiveDomain get primaryDomain;
  PhraseKey get introPhrase;

  /// Ghost-hand demonstration of how to play.
  Future<void> playDemo(BuildContext context);

  GameItem generateItem(double difficulty, GameContent content);

  Stream<TrialResult> get trials;
}
