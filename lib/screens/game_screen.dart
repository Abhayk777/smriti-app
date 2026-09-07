import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/repo/ability_repo.dart';
import '../core/repo/event_repo.dart';
import '../games/cognitive_game.dart';
import '../games/session_runner.dart';

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
/// Games never touch DB directly — this screen owns the SessionRunner.
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
    }
    super.dispose();
  }

  Future<void> _initSession() async {
    // Load content
    final content = await _loadGameContent();

    // Create game
    final game = _createGame(widget.gameId);
    if (game == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    // Create session runner
    final runner = SessionRunner(
      eventRepo: _eventRepo,
      abilityRepo: _abilityRepo,
      content: content,
    );

    // Start session
    await runner.start([game]);

    // Listen to feedback
    _feedbackSub = runner.feedback.listen((feedback) {
      if (mounted) {
        setState(() => _lastFeedback = feedback);
        // Clear feedback after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _lastFeedback = null);
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

  Future<GameContent> _loadGameContent() async {
    try {
      final jsonStr = await rootBundle
          .loadString('assets/mock_content/mock_content.json');
      final json = jsonDecode(jsonStr) as Map<String, Object?>;
      return GameContent.fromJson(json);
    } catch (_) {
      return GameContent(version: '1.0', marketItems: const []);
    }
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

  void _endSession({bool completed = false}) {
    if (_sessionEnded) return;
    _sessionEnded = true;
    _runner?.end(completed: completed);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.terracotta),
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
                      ? _buildGameWidget()
                      : const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.terracotta),
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
    final minutes = _elapsed.inMinutes;
    final seconds = _elapsed.inSeconds % 60;
    final remaining = 6 - minutes;
    final progress = _elapsed.inSeconds / 360.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.raisedSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Game name
          Text(
            _gameName(widget.gameId),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          const Spacer(),

          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.pageBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  size: 20,
                  color: remaining <= 1
                      ? AppColors.terracotta
                      : AppColors.secondaryText,
                ),
                const SizedBox(width: 8),
                Text(
                  '$minutes:${seconds.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: remaining <= 1
                        ? AppColors.terracotta
                        : AppColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Progress
          SizedBox(
            width: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: AppColors.border,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.terracotta),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Exit button
          IconButton(
            onPressed: () => _endSession(completed: false),
            icon: const Icon(Icons.close, size: 28),
            color: AppColors.secondaryText,
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
      top: 80,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: _lastFeedback != null ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isPraise
                  ? AppColors.leafGreen.withValues(alpha: 0.9)
                  : AppColors.wovenMat.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              isPraise ? '✨ Well done!' : '👍 Nice try!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.onColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _gameName(String id) {
    const names = {
      'market_basket': 'Market Basket',
      'faces_of_family': 'Faces of My Family',
      'sort_harvest': 'Sort the Harvest',
      'trace_path': 'Trace the Path',
      'my_day': 'My Day',
      'lamps_festival': 'Lamps of the Festival',
      'name_harvest': 'Name the Harvest',
      'weaving_patterns': 'Weaving Patterns',
      'sounds_home': 'Sounds of Home',
    };
    return names[id] ?? id;
  }
}
