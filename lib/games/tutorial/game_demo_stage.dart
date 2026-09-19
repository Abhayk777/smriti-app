import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/i18n/locale_controller.dart';
import '../../core/i18n/app_strings.dart';
import '../../ui/smriti_ui.dart';
import '../cognitive_game.dart';
import '../faces_of_family/faces_game.dart';
import '../faces_of_family/faces_widget.dart';
import '../game_catalog.dart';
import '../hint/game_hint.dart';
import '../lamps_festival/lamps_game.dart';
import '../lamps_festival/lamps_widget.dart';
import '../market_basket/market_basket_game.dart';
import '../market_basket/market_basket_widget.dart';
import '../my_day/my_day_game.dart';
import '../my_day/my_day_widget.dart';
import '../name_harvest/name_harvest_game.dart';
import '../name_harvest/name_harvest_widget.dart';
import '../sort_harvest/sort_harvest_game.dart';
import '../sort_harvest/sort_harvest_widget.dart';
import '../sounds_home/sounds_home_game.dart';
import '../sounds_home/sounds_home_widget.dart';
import '../trace_path/trace_path_game.dart';
import '../trace_path/trace_path_widget.dart';
import '../ui/game_chrome.dart';
import '../weaving_patterns/weaving_game.dart';
import '../weaving_patterns/weaving_widget.dart';
import 'demo_stage.dart' show DemoHand, DemoRipple;

/// The size of a phone's game area. The demonstration lays the real game out
/// at this size and scales it to fit the tutorial screen.
const Size kDemoScreen = Size(412, 700);

/// The tutorial's demonstration: the **real game**, running on easy items,
/// played by a ghost hand that finds the correct answer, moves to it and taps
/// it. Because it is the real game widget, the tutorial can never drift from
/// what the elder will actually see.
///
/// Nothing here is saved: the game's results go nowhere, and the elder's own
/// touches are ignored while the demonstration plays.
class GameDemoStage extends StatefulWidget {
  const GameDemoStage({super.key, required this.gameId});

  final String gameId;

  @override
  State<GameDemoStage> createState() => _GameDemoStageState();
}

class _GameDemoStageState extends State<GameDemoStage> with SingleTickerProviderStateMixin {
  static const _hand = DemoHand(width: 104);

  final GlobalKey _stageKey = GlobalKey();
  final GlobalKey _areaKey = GlobalKey();

  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  bool _alive = true;
  Timer? _timer;
  int _cycle = 0;
  Widget? _gameWidget;

  Offset _handAt = Offset(kDemoScreen.width + 10, kDemoScreen.height + 10);
  Offset _rippleAt = Offset.zero;
  bool _handVisible = false;
  bool _handDown = false;
  int _handMs = 0;

  GameInfo? get _info => gameInfoFor(widget.gameId);

  @override
  void initState() {
    super.initState();
    unawaited(_loop());
  }

  @override
  void dispose() {
    _alive = false;
    _timer?.cancel();
    _ripple.dispose();
    super.dispose();
  }

  // ── Timing ───────────────────────────────────────────────────────────────

  Future<bool> _wait(int ms) {
    final done = Completer<void>();
    _timer = Timer(Duration(milliseconds: ms), done.complete);
    return done.future.then((_) => _alive);
  }

  // ── Building the real game on easy, fixed items ─────────────────────────

  static GameContent _content() {
    const items = [
      ('rice', 'item.rice', '🍚', 'grain'),
      ('tomato', 'item.tomato', '🍅', 'vegetable'),
      ('potato', 'item.potato', '🥔', 'vegetable'),
      ('banana', 'item.banana', '🍌', 'fruit'),
      ('milk', 'item.milk', '🥛', 'dairy'),
      ('tea', 'item.tea', '🍵', 'pantry'),
      ('dal', 'item.dal', '🫘', 'pulse'),
      ('brinjal', 'item.brinjal', '🍆', 'vegetable'),
    ];
    return GameContent(
      version: 'demo',
      marketItems: [
        for (final i in items) MarketItem(id: i.$1, labelKey: i.$2, iconAsset: i.$3, category: i.$4),
      ],
      people: const [
        PersonItem(id: 'p1', name: 'Sunita', relationship: 'mother', photoPath: ''),
        PersonItem(id: 'p2', name: 'Rohan', relationship: 'son', photoPath: ''),
        PersonItem(id: 'p3', name: 'Meera', relationship: 'daughter', photoPath: ''),
        PersonItem(id: 'p4', name: 'Arjun', relationship: 'grandson', photoPath: ''),
      ],
      routineItems: const [
        RoutineEntry(id: 'wake_up', timeMin: 360, labelKey: 'Wake Up', iconAsset: '☀️'),
        RoutineEntry(id: 'breakfast', timeMin: 480, labelKey: 'Breakfast', iconAsset: '🍳'),
        RoutineEntry(id: 'lunch', timeMin: 720, labelKey: 'Lunch', iconAsset: '🍛'),
        RoutineEntry(id: 'dinner', timeMin: 1200, labelKey: 'Dinner', iconAsset: '🍽️'),
      ],
    );
  }

  /// A fresh game and an easy item for it, plus the widget that plays it.
  Widget _buildGame() {
    final id = widget.gameId;
    final random = Random(11 + _cycle);
    const difficulty = -2.0; // the easiest level

    GameItem tune(GameItem item, Map<String, Object?> overrides) => GameItem(
          id: item.id,
          difficulty: item.difficulty,
          context: item.context,
          payload: {...item.payload, ...overrides},
        );

    switch (id) {
      case 'market_basket':
        final game = MarketBasketGame(random: random);
        final item = tune(game.generateItem(difficulty, _content()), {
          'studySeconds': 3,
          'delaySeconds': 1,
        });
        return MarketBasketWidget(game: game, item: item, onComplete: () {});
      case 'faces_of_family':
        final game = FacesGame(random: random);
        final item = tune(game.generateItem(difficulty, _content()), {'revealSeconds': 0});
        return FacesWidget(game: game, item: item, onComplete: () {});
      case 'sort_harvest':
        final game = SortHarvestGame(random: random);
        return SortHarvestWidget(
          game: game,
          item: game.generateItem(difficulty, _content()),
          onComplete: () {},
        );
      case 'trace_path':
        final game = TracePathGame(random: random);
        return TracePathWidget(
          game: game,
          item: game.generateItem(difficulty, _content()),
          onComplete: () {},
        );
      case 'my_day':
        final game = MyDayGame(random: random);
        return MyDayWidget(
          game: game,
          item: game.generateItem(difficulty, _content()),
          onComplete: () {},
        );
      case 'lamps_festival':
        final game = LampsGame(random: random);
        return LampsWidget(
          game: game,
          item: game.generateItem(difficulty, _content()),
          onComplete: () {},
        );
      case 'name_harvest':
        final game = NameHarvestGame(random: random);
        return NameHarvestWidget(
          game: game,
          item: game.generateItem(difficulty, _content()),
          onComplete: () {},
        );
      case 'weaving_patterns':
        final game = WeavingGame(random: random);
        return WeavingWidget(
          game: game,
          item: game.generateItem(difficulty, _content()),
          onComplete: () {},
        );
      case 'sounds_home':
        final game = SoundsHomeGame(random: random);
        final item = tune(game.generateItem(difficulty, _content()), {
          'durationSeconds': 60,
          'stimuli': <Map<String, Object>>[
            {'timeMs': 2600, 'sound': SoundsHomeGame.targetSound, 'isTarget': true},
            {'timeMs': 6200, 'sound': 'rain', 'isTarget': false},
          ],
        });
        return SoundsHomeWidget(game: game, item: item, onComplete: () {});
    }
    return const SizedBox.shrink();
  }

  // ── Finding things in the running game ───────────────────────────────────

  /// The elements the game itself marks as "the answer": exactly what the hint
  /// glow would light up.
  List<Element> _answers() {
    final ctx = _areaKey.currentContext;
    if (ctx == null) return const [];
    final out = <Element>[];
    void visit(Element e) {
      final w = e.widget;
      if (w is HintGlow && w.isAnswer) {
        out.add(e);
        return;
      }
      e.visitChildren(visit);
    }

    ctx.visitChildElements(visit);
    return out;
  }

  Element? _find(Element root, bool Function(Widget w) test) {
    Element? found;
    void visit(Element e) {
      if (found != null) return;
      if (test(e.widget)) {
        found = e;
        return;
      }
      e.visitChildren(visit);
    }

    root.visitChildren(visit);
    return found;
  }

  Element? _findInArea(bool Function(Widget w) test) {
    final ctx = _areaKey.currentContext;
    if (ctx == null) return null;
    Element? found;
    void visit(Element e) {
      if (found != null) return;
      if (test(e.widget)) {
        found = e;
        return;
      }
      e.visitChildren(visit);
    }

    ctx.visitChildElements(visit);
    return found;
  }

  /// Where an element is, in the stage's own coordinates.
  Rect? _rectOf(Element e) {
    final stage = _stageKey.currentContext?.findRenderObject();
    final box = e.findRenderObject();
    if (stage is! RenderBox || box is! RenderBox || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: stage);
    return topLeft & box.size;
  }

  VoidCallback? _tapCallback(Element root) {
    final found = _find(root, (w) =>
        (w is BouncyTap && w.onTap != null) ||
        (w is ElevatedButton && w.onPressed != null) ||
        (w is IconButton && w.tooltip == 'Move Up' && w.onPressed != null));
    final w = found?.widget;
    if (w is BouncyTap) return w.onTap;
    if (w is ElevatedButton) return w.onPressed;
    if (w is IconButton) return w.onPressed;
    return null;
  }

  // ── The ghost hand ───────────────────────────────────────────────────────

  Future<bool> _moveTo(Rect rect) async {
    final tip = _hand.tipOffset;
    // Aim at the middle of the target, a little above the bottom edge.
    final c = Offset(rect.center.dx, rect.center.dy);
    setState(() {
      _handMs = 850;
      _handAt = c - tip;
      _handVisible = true;
    });
    return _wait(930);
  }

  Future<bool> _press(Offset at, VoidCallback? action) async {
    setState(() {
      _handDown = true;
      _rippleAt = at;
    });
    _ripple.forward(from: 0);
    if (!await _wait(230)) return false;
    action?.call();
    if (mounted) setState(() => _handDown = false);
    return _alive;
  }

  /// Moves to [e], taps it, and runs its tap handler.
  Future<bool> _tapElement(Element e, {VoidCallback? action}) async {
    final rect = _rectOf(e);
    if (rect == null) return false;
    if (!await _moveTo(rect)) return false;
    return _press(rect.center, action ?? _tapCallback(e));
  }

  /// Waits until the game shows an answer to tap (it may still be showing its
  /// items, or lighting up lamps).
  Future<List<Element>?> _awaitAnswers(int timeoutMs) async {
    var waited = 0;
    while (waited < timeoutMs) {
      final a = _answers();
      if (a.isNotEmpty) return a;
      if (!await _wait(250)) return null;
      waited += 250;
    }
    return const [];
  }

  // ── The script ───────────────────────────────────────────────────────────

  Future<void> _loop() async {
    while (_alive) {
      if (!await _wait(400)) return;
      setState(() {
        _cycle++;
        _gameWidget = _buildGame();
        _handAt = Offset(kDemoScreen.width - 40, kDemoScreen.height + 20);
        _handVisible = false;
        _handMs = 0;
      });
      if (!await _wait(600)) return;

      switch (widget.gameId) {
        case 'name_harvest':
          if (!await _playNameHarvest()) return;
        case 'sounds_home':
          if (!await _playSounds()) return;
        default:
          if (!await _playGeneric()) return;
      }

      if (!await _wait(1800)) return;
      setState(() => _handVisible = false);
      if (!await _wait(700)) return;
    }
  }

  /// Tap each correct answer as it appears; finish with "Done" where the
  /// game needs it.
  Future<bool> _playGeneric() async {
    var first = true;
    for (var i = 0; i < 12; i++) {
      final answers = await _awaitAnswers(first ? 22000 : 2500);
      if (answers == null) return false;
      if (answers.isEmpty) break;
      first = false;
      if (!await _tapElement(answers.first)) return false;
      if (!await _wait(1000)) return false;
    }

    if (widget.gameId == 'market_basket' || widget.gameId == 'my_day') {
      final done = _findInArea((w) => w is ElevatedButton && w.onPressed != null);
      if (done != null) {
        if (!await _tapElement(done)) return false;
      }
    }
    return true;
  }

  Future<bool> _playNameHarvest() async {
    final answers = await _awaitAnswers(8000);
    if (answers == null) return false;
    if (answers.isEmpty) return true;
    final field = _find(answers.first, (w) => w is TextField);
    final tf = field?.widget;
    if (tf is! TextField || tf.controller == null) return true;
    final rect = _rectOf(answers.first);
    if (rect == null) return true;

    if (!await _moveTo(rect)) return false;
    if (!await _press(rect.center, null)) return false;

    for (final word in const ['Rice', 'Milk', 'Banana']) {
      for (var i = 1; i <= word.length; i++) {
        tf.controller!.text = word.substring(0, i);
        if (mounted) setState(() {});
        if (!await _wait(120)) return false;
      }
      if (!await _wait(350)) return false;
      tf.onSubmitted?.call(word);
      if (mounted) setState(() {});
      if (!await _wait(900)) return false;
    }
    return true;
  }

  Future<bool> _playSounds() async {
    // 1. Hear the bird.
    final hear = _findInArea((w) => w is OutlinedButton && w.onPressed != null);
    if (hear != null && !await _tapElement(hear)) return false;
    if (!await _wait(2400)) return false;

    // 2. Start.
    final answers = await _awaitAnswers(3000);
    if (answers == null) return false;
    if (answers.isNotEmpty && !await _tapElement(answers.first)) return false;

    // 3. Wait for the bird, then tap the drum.
    final drum = _findInArea((w) => w is GestureDetector && w.onTapDown != null);
    if (drum == null) return true;
    final rect = _rectOf(drum);
    if (rect == null) return true;
    if (!await _moveTo(rect)) return false;
    if (!await _wait(700)) return false;
    final gd = drum.widget as GestureDetector;
    if (!await _press(rect.center, () => gd.onTapDown?.call(TapDownDetails()))) return false;
    return _wait(3500);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final info = _info;
    if (info == null) return const SizedBox.shrink();
    final lang = LocaleController.instance.currentLanguage;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final base = MediaQuery.of(context);

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        key: _stageKey,
        width: kDemoScreen.width,
        height: kDemoScreen.height,
        child: MediaQuery(
          data: base.copyWith(
            size: kDemoScreen,
            padding: EdgeInsets.zero,
            viewPadding: EdgeInsets.zero,
            viewInsets: EdgeInsets.zero,
          ),
          child: ClipRect(
            child: Stack(
              children: [
                Positioned.fill(child: GameBackdrop(color: info.color)),
                Column(
                  children: [
                    GameTopBar(
                      info: info,
                      title: AppStrings.gameTitle(lang, widget.gameId),
                      elapsed: const Duration(seconds: 9),
                    ),
                    Expanded(
                      child: KeyedSubtree(
                        key: _areaKey,
                        child: IgnorePointer(
                          child: KeyedSubtree(
                            key: ValueKey(_cycle),
                            child: _gameWidget ?? const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedBuilder(
                  animation: _ripple,
                  builder: (context, _) => Positioned(
                    left: _rippleAt.dx - 60,
                    top: _rippleAt.dy - 60,
                    width: 120,
                    height: 120,
                    child: Center(child: DemoRipple(progress: _ripple.value, size: 96)),
                  ),
                ),
                AnimatedPositioned(
                  duration: Duration(milliseconds: still ? 0 : _handMs),
                  curve: Curves.easeInOutCubic,
                  left: _handAt.dx,
                  top: _handAt.dy,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _handVisible ? 0.97 : 0,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 140),
                        scale: _handDown ? 0.9 : 1,
                        alignment: Alignment(
                          (DemoHand.tip.dx * 2) - 1,
                          (DemoHand.tip.dy * 2) - 1,
                        ),
                        child: _hand,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

