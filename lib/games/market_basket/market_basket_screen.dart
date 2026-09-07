import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../core/app_services.dart';
import '../cognitive_game.dart';
import '../session_runner.dart';
import 'market_basket_game.dart';

/// Bare playable surface for Market Basket.
///
/// A06 built the game's logic and proved it against the session runner in
/// tests, but nothing could play it. This is the thinnest widget that drives
/// the real harness — show the list, hide it, take the picks, submit — so the
/// write path can be exercised by a person. The elder-facing design, the
/// ghost-hand animation and the rest of the games are A13.
class MarketBasketScreen extends StatefulWidget {
  const MarketBasketScreen({
    super.key,
    required this.services,
    required this.content,
  });

  final AppServices services;

  /// Item catalogue. Until content includes market goods this comes from the
  /// mock JSON the caller loads.
  final GameContent content;

  @override
  State<MarketBasketScreen> createState() => _MarketBasketScreenState();
}

class _MarketBasketScreenState extends State<MarketBasketScreen> {
  late final MarketBasketGame _game = MarketBasketGame();
  late final SessionRunner _runner = SessionRunner(
    eventRepo: widget.services.eventRepo,
    abilityRepo: widget.services.abilityRepo,
    content: widget.content,
  );

  GameItem? _item;
  bool _showingList = true;
  final Set<String> _picked = {};
  int _trialsDone = 0;
  DateTime? _shownAt;
  DateTime? _firstTouchAt;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _runner.end(completed: false);
    _game.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    await _runner.start([_game]);
    await _nextItem();
  }

  Future<void> _nextItem() async {
    final item = await _runner.nextItem(_game);
    if (!mounted) return;

    if (item == null) {
      // Six-minute cap spent.
      await _runner.end(completed: true);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() {
      _item = item;
      _showingList = true;
      _picked.clear();
      _shownAt = DateTime.now();
      _firstTouchAt = null;
    });
  }

  List<MarketItem> get _shelf =>
      (_item!.payload['shelf']! as List<Object?>).cast<MarketItem>();

  List<MarketItem> get _targets =>
      (_item!.payload['target']! as List<Object?>).cast<MarketItem>();

  void _hideList() => setState(() {
        _showingList = false;
        _shownAt = DateTime.now();
      });

  void _toggle(String id) {
    _firstTouchAt ??= DateTime.now();
    setState(() {
      if (!_picked.remove(id)) _picked.add(id);
    });
  }

  Future<void> _submit() async {
    final item = _item;
    if (item == null) return;

    final now = DateTime.now();
    final firstTouch = _firstTouchAt ?? now;

    // The runner turns these into initiationMs/movementMs/responseTimeMs.
    _game.submit(
      item: item,
      chosenIds: _picked.toList(),
      initiationMs: firstTouch.difference(_shownAt ?? now).inMilliseconds,
      movementMs: now.difference(firstTouch).inMilliseconds,
    );

    // Let the runner persist the trial before asking for the next item.
    await _runner.feedback.first;
    if (!mounted) return;
    setState(() => _trialsDone++);
    await _nextItem();
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        title: Text('Market Basket · $_trialsDone done'),
      ),
      body: SafeArea(
        child: item == null
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20),
                child: _showingList
                    ? _buildList()
                    : _buildShelf(),
              ),
      ),
    );
  }

  Widget _buildList() {
    return Column(
      key: const Key('mb_list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Remember these:', style: TextStyle(fontSize: 22)),
        const SizedBox(height: 12),
        for (final target in _targets)
          Text(
            target.labelKey,
            key: Key('mb_target_${target.id}'),
            style: const TextStyle(fontSize: 26),
          ),
        const Spacer(),
        ElevatedButton(
          key: const Key('mb_ready'),
          onPressed: _hideList,
          child: const Text('Ready'),
        ),
      ],
    );
  }

  Widget _buildShelf() {
    return Column(
      key: const Key('mb_shelf'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pick them from the shelf:', style: TextStyle(fontSize: 22)),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final shelfItem in _shelf)
                  ChoiceChip(
                    key: Key('mb_pick_${shelfItem.id}'),
                    label: Text(shelfItem.labelKey),
                    selected: _picked.contains(shelfItem.id),
                    onSelected: (_) => _toggle(shelfItem.id),
                  ),
              ],
            ),
          ),
        ),
        ElevatedButton(
          key: const Key('mb_submit'),
          onPressed: _submit,
          child: const Text('Done'),
        ),
      ],
    );
  }
}
