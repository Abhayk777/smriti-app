import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/progression/difficulty_source.dart';
import '../core/progression/progression_service.dart';
import '../core/repo/ability_repo.dart';
import '../core/repo/content_repo.dart';
import '../core/repo/event_repo.dart';
import '../core/sync/sync_engine.dart';
import '../games/cognitive_game.dart';
import '../games/game_catalog.dart';
import '../games/session_runner.dart';
import '../ui/smriti_ui.dart';

// Game imports
import '../games/market_basket/market_basket_game.dart';
import '../games/market_basket/market_basket_widget.dart';
import '../games/faces_of_family/faces_game.dart';
import '../games/faces_of_family/faces_widget.dart';
import '../games/sort_harvest/sort_harvest_game.dart';
import '../games/sort_harvest/sort_harvest_widget.dart';
import '../games/trace_path/trace_path_game.dart';
import '../games/trace_path/trace_path_widget.dart';
import '../games/my_day/my_day_game.dart';
import '../games/my_day/my_day_widget.dart';
import '../games/lamps_festival/lamps_game.dart';
import '../games/lamps_festival/lamps_widget.dart';
import '../games/name_harvest/name_harvest_game.dart';
import '../games/name_harvest/name_harvest_widget.dart';
import '../games/weaving_patterns/weaving_game.dart';
import '../games/weaving_patterns/weaving_widget.dart';
import '../games/sounds_home/sounds_home_game.dart';
import '../games/sounds_home/sounds_home_widget.dart';

/// Generic game host screen.
///
/// Manages the session lifecycle, renders whichever game widget is active,
/// shows session timer, feedback overlay, and exit controls.
/// Games never touch DB directly; this screen owns the SessionRunner.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.gameId,
  });

  final String gameId;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final EventRepo _eventRepo;
  late final AbilityRepo _abilityRepo;
  SessionRunner? _runner;
  CognitiveGame? _game;
  GameItem? _currentItem;
  bool _sessionEnded = false;
  bool _loading = true;
  StreamSubscription<TrialFeedback>? _feedbackSub;
  TrialFeedback? _lastFeedback;
  int _feedbackCount = 0;

  /// Faces of My Family is played with the elder's real family, so it needs
  /// at least two people from the caregiver before it can start.
  bool _needsFamily = false;

  GameInfo? get _info => gameInfoFor(widget.gameId);
  Color get _color => _info?.color ?? AppColors.terracotta;
  Timer? _timerUpdate;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _eventRepo = EventRepo(appDatabase);
    _abilityRepo = AbilityRepo(appDatabase);
    _initSession();
  }

  @override
  void dispose() {
    _feedbackSub?.cancel();
    _timerUpdate?.cancel();
    if (!_sessionEnded && _runner != null) {
      _runner!.end(completed: false);
      unawaited(ProgressionService.instance.onSessionEnded(widget.gameId));
    }
    super.dispose();
  }

  Future<void> _initSession() async {
    // Load content
    final content = await _loadGameContent();

    if (widget.gameId == 'faces_of_family' &&
        content.people.where((p) => !p.isDeceased).length < 2) {
      if (mounted) {
        setState(() {
          _needsFamily = true;
          _loading = false;
        });
      }
      return;
    }

    // Create game
    final game = _createGame(widget.gameId);
    if (game == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    // Seed/ease this game's level and prime the in-memory cache
    // (docs/PROGRESSION_PLAN.md §6.7, §7) before the session reads it.
    await ProgressionService.instance.onSessionStarted(widget.gameId);

    // Create session runner
    final runner = SessionRunner(
      eventRepo: _eventRepo,
      abilityRepo: _abilityRepo,
      content: content,
      difficultySource: LevelDifficultySource<CognitiveGame, TrialResult>(
        ProgressionService.instance,
        (g) => g.id,
        (r) => r.correct,
      ),
    );

    // Start session
    await runner.start([game]);

    // Listen to feedback
    _feedbackSub = runner.feedback.listen((feedback) {
      if (mounted) {
        final shown = ++_feedbackCount;
        setState(() => _lastFeedback = feedback);
        // Clear feedback after 2 seconds, unless a newer one replaced it
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && shown == _feedbackCount) {
            setState(() => _lastFeedback = null);
          }
        });
      }
    });

    // Timer update
    _timerUpdate = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && runner.isRunning) {
        setState(() => _elapsed = runner.elapsed);
      }
    });

    setState(() {
      _game = game;
      _runner = runner;
      _loading = false;
    });

    // Get first item
    _nextItem();
  }

  CognitiveGame? _createGame(String gameId) {
    switch (gameId) {
      case 'market_basket':
        return MarketBasketGame();
      case 'faces_of_family':
        return FacesGame();
      case 'sort_harvest':
        return SortHarvestGame();
      case 'trace_path':
        return TracePathGame();
      case 'my_day':
        return MyDayGame();
      case 'lamps_festival':
        return LampsGame();
      case 'name_harvest':
        return NameHarvestGame();
      case 'weaving_patterns':
        return WeavingGame();
      case 'sounds_home':
        return SoundsHomeGame();
      default:
        return null;
    }
  }

  /// Game content: the bundled item catalogue, with the family and the daily
  /// routine taken from the elder's own People and RoutineItems tables
  /// (pulled from the caregiver's web app).
  Future<GameContent> _loadGameContent() async {
    GameContent base;
    try {
      final jsonStr = await rootBundle
          .loadString('assets/mock_content/mock_content.json');
      final json = jsonDecode(jsonStr) as Map<String, Object?>;
      base = GameContent.fromJson(json);
    } catch (_) {
      base = GameContent(version: '1.0', marketItems: const []);
    }

    List<PersonItem> family = const [];
    try {
      final people = await ContentRepo(appDatabase).getPeople();
      family = [
        for (final person in people)
          PersonItem(
            id: person.id,
            name: person.name,
            relationship: person.relationship,
            photoPath: person.photoPath,
            voicePath: person.voicePath,
            memoryPrompt: person.memoryPrompt,
            isDeceased: person.isDeceased,
          ),
      ];
    } catch (e) {
      debugPrint('Could not load family for games: $e');
    }

    List<RoutineEntry> routine = const [];
    try {
      final items = await ContentRepo(appDatabase).getRoutineItems();
      routine = [
        for (final item in items)
          RoutineEntry(
            id: item.id,
            timeMin: item.timeMin,
            labelKey: item.labelKey,
            iconAsset: item.iconAsset,
          ),
      ];
    } catch (e) {
      debugPrint('Could not load routine for games: $e');
    }

    return GameContent(
      version: base.version,
      marketItems: base.marketItems,
      people: family,
      routineItems: routine,
    );
  }

  Future<void> _nextItem() async {
    if (_runner == null || _game == null || _sessionEnded) return;

    final item = await _runner!.nextItem(_game!);
    if (item == null) {
      // Session cap reached
      _endSession(completed: true);
      return;
    }

    setState(() => _currentItem = item);
  }

  Future<void> _endSession({bool completed = false}) async {
    if (_sessionEnded) return;
    _sessionEnded = true;
    _timerUpdate?.cancel();
    _runner?.end(completed: completed);
    unawaited(SyncEngine.defaultInstance.run(trigger: SyncTrigger.sessionEnded));
    unawaited(ProgressionService.instance.onSessionEnded(widget.gameId));

    if (!mounted) return;

    var restNow = false;

    // Show session summary dialog so user/caregiver sees what was played and how long
    if (_elapsed.inSeconds >= 3) {
      final mins = _elapsed.inMinutes;
      final secs = _elapsed.inSeconds % 60;
      final durationStr = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';
      final name = _gameName(widget.gameId);

      final restAdvice = await ProgressionService.instance.restAdvice();
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final isCompact = MediaQuery.of(ctx).size.height < 500;
          return Dialog(
            clipBehavior: Clip.antiAlias,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: restAdvice.show
                  ? RestCardDialog(
                      isCompact: isCompact,
                      minutesToday: restAdvice.minutesToday,
                      onRestNow: () {
                        unawaited(ProgressionService.instance.onRestCardAnswered(keepPlaying: false));
                        restNow = true;
                        Navigator.of(ctx).pop();
                      },
                      onKeepPlaying: () {
                        unawaited(ProgressionService.instance.onRestCardAnswered(keepPlaying: true));
                        Navigator.of(ctx).pop();
                      },
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            color: _color,
                            padding: EdgeInsets.symmetric(vertical: isCompact ? 16 : 26),
                            child: Column(
                              children: [
                                PopIn(
                                  child: IconMedallion(
                                    icon: Icons.emoji_events_rounded,
                                    color: _color,
                                    size: isCompact ? 64 : 88,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  completed ? 'Session Complete' : 'Great Effort',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const GamosaBand(height: 10),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                            child: Column(
                              children: [
                                Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.pageBackground,
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.schedule_rounded, color: _color, size: 26),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          'Time Played: $durationStr',
                                          style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: isCompact ? 16 : 22),
                                SizedBox(
                                  width: double.infinity,
                                  height: 64,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    style: ElevatedButton.styleFrom(backgroundColor: _color),
                                    child: const Text(
                                      'Back to Games',
                                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      );
    }

    if (mounted) {
      if (restNow) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconMedallion(
                icon: _info?.icon ?? Icons.extension_rounded,
                color: _color,
                size: 96,
                background: _color.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 20),
              Text(
                'Getting ready...',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _color,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 160,
                child: LinearProgressIndicator(
                  color: _color,
                  backgroundColor: _color.withValues(alpha: 0.15),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_needsFamily) {
      return Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: _gameName(widget.gameId),
                icon: _info?.icon ?? Icons.people_alt_rounded,
                color: _color,
              ),
              Expanded(
                child: EmptyState(
                  icon: Icons.people_alt_rounded,
                  color: _color,
                  title: 'Your family photos are on their way',
                  message: 'This game uses your own family. It will be ready '
                      'once your caregiver adds at least two family members.',
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(backgroundColor: _color),
                    icon: const Icon(Icons.arrow_back_rounded, size: 28),
                    label: const Text(
                      'Back to Games',
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar with timer and exit
                _buildTopBar(),

                // Game content
                Expanded(
                  child: _currentItem != null
                      ? AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: KeyedSubtree(
                            key: ValueKey(_currentItem),
                            child: _buildGameWidget(),
                          ),
                        )
                      : Center(
                          child: CircularProgressIndicator(color: _color),
                        ),
                ),
              ],
            ),

            // Feedback overlay
            if (_lastFeedback != null) _buildFeedbackOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final isCompact = MediaQuery.of(context).size.height < 500;
    final minutes = _elapsed.inMinutes;
    final seconds = _elapsed.inSeconds % 60;
    final progress = _elapsed.inSeconds / 360.0;
    final deep = Color.lerp(_color, Colors.black, 0.22)!;

    return Container(
      color: _color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, isCompact ? 6 : 10, 12, isCompact ? 6 : 10),
            child: Row(
              children: [
                IconMedallion(
                  icon: _info?.icon ?? Icons.extension_rounded,
                  color: _color,
                  size: 48,
                ),
                const SizedBox(width: 12),
                // Game name
                Expanded(
                  child: Text(
                    _gameName(widget.gameId),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: deep,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule_rounded, size: 22, color: AppColors.onColor),
                      const SizedBox(width: 6),
                      Text(
                        '$minutes:${seconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: AppColors.onColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Exit button
                IconButton(
                  tooltip: 'Stop playing',
                  onPressed: () => _endSession(completed: false),
                  iconSize: 30,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(52, 52),
                    backgroundColor: AppColors.raisedSurface,
                  ),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.primaryText,
                ),
              ],
            ),
          ),

          // Progress through the 6-minute session
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: deep,
            valueColor: const AlwaysStoppedAnimation(AppColors.marigold),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildGameWidget() {
    final item = _currentItem!;

    switch (widget.gameId) {
      case 'market_basket':
        return MarketBasketWidget(
          game: _game! as MarketBasketGame,
          item: item,
          onComplete: _nextItem,
        );
      case 'faces_of_family':
        return FacesWidget(
          game: _game! as FacesGame,
          item: item,
          onComplete: _nextItem,
        );
      case 'sort_harvest':
        return SortHarvestWidget(
          game: _game! as SortHarvestGame,
          item: item,
          onComplete: _nextItem,
        );
      case 'trace_path':
        return TracePathWidget(
          game: _game! as TracePathGame,
          item: item,
          onComplete: _nextItem,
        );
      case 'my_day':
        return MyDayWidget(
          game: _game! as MyDayGame,
          item: item,
          onComplete: _nextItem,
        );
      case 'lamps_festival':
        return LampsWidget(
          game: _game! as LampsGame,
          item: item,
          onComplete: _nextItem,
        );
      case 'name_harvest':
        return NameHarvestWidget(
          game: _game! as NameHarvestGame,
          item: item,
          onComplete: _nextItem,
        );
      case 'weaving_patterns':
        return WeavingWidget(
          game: _game! as WeavingGame,
          item: item,
          onComplete: _nextItem,
        );
      case 'sounds_home':
        return SoundsHomeWidget(
          game: _game! as SoundsHomeGame,
          item: item,
          onComplete: _nextItem,
        );
      default:
        return Center(
          child: Text(
            'Unknown game: ${widget.gameId}',
            style: const TextStyle(
                fontSize: 20, color: AppColors.primaryText),
          ),
        );
    }
  }

  Widget _buildFeedbackOverlay() {
    final isPraise = _lastFeedback!.tone == FeedbackTone.praise;
    return Positioned(
      top: 96,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: Center(
          child: PopIn(
            key: ValueKey(_feedbackCount),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 26, 10),
              decoration: BoxDecoration(
                color: isPraise ? AppColors.leafGreen : AppColors.indigo,
                borderRadius: BorderRadius.circular(48),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconMedallion(
                    icon: isPraise ? Icons.star_rounded : Icons.thumb_up_alt_rounded,
                    color: isPraise ? AppColors.marigoldDark : AppColors.indigo,
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isPraise ? 'Well done!' : 'Nice try!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _gameName(String id) => gameInfoFor(id)?.name ?? id;
}

/// Presentational dialog content shown when the daily rest advice is due.
class RestCardDialog extends StatelessWidget {
  const RestCardDialog({
    super.key,
    required this.isCompact,
    required this.minutesToday,
    required this.onRestNow,
    required this.onKeepPlaying,
  });

  final bool isCompact;
  final int minutesToday;
  final VoidCallback onRestNow;
  final VoidCallback onKeepPlaying;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: Container(
        padding: EdgeInsets.all(isCompact ? 18 : 24),
        decoration: BoxDecoration(
          color: Color.lerp(AppColors.leafGreen, Colors.white, 0.85),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconMedallion(
                  icon: Icons.local_cafe_rounded,
                  color: AppColors.leafGreen,
                  size: isCompact ? 48 : 56,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Time for a little rest',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 12 : 16),
            Text(
              'You have played for $minutesToday minutes today. Well done! How about a cup of tea or a short walk?',
              style: const TextStyle(
                fontSize: 20,
                height: 1.3,
                color: AppColors.primaryText,
              ),
            ),
            SizedBox(height: isCompact ? 16 : 22),
            SizedBox(
              height: 64,
              child: ElevatedButton(
                onPressed: onRestNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.leafGreen,
                ),
                child: const Text(
                  'Rest now',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 64,
              child: OutlinedButton(
                onPressed: onKeepPlaying,
                child: const Text(
                  'Keep playing',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
