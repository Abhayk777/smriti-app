import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../cognitive_game.dart';
import 'market_basket_game.dart';

/// Playable Market Basket widget.
///
/// Flow: Show shopping list → brief delay → show shelf → elder picks items.
/// Times initiation (to first tap) and movement (picking duration).
/// Uses emoji icons from content.
class MarketBasketWidget extends StatefulWidget {
  const MarketBasketWidget({
    super.key,
    required this.game,
    required this.item,
    required this.onComplete,
  });

  final MarketBasketGame game;
  final GameItem item;
  final VoidCallback onComplete;

  @override
  State<MarketBasketWidget> createState() => _MarketBasketWidgetState();
}

class _MarketBasketWidgetState extends State<MarketBasketWidget>
    with TickerProviderStateMixin {
  // Phases: showing_list → delay → picking → done
  String _phase = 'showing_list';
  final List<String> _picked = [];
  DateTime? _shelfShownAt;
  DateTime? _firstTapAt;
  late final List<MarketItem> _targets;
  late final List<MarketItem> _shelf;
  late final Set<String> _targetIds;

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _targets =
        (widget.item.payload['target'] as List<Object?>).cast<MarketItem>();
    _shelf =
        (widget.item.payload['shelf'] as List<Object?>).cast<MarketItem>();
    _targetIds = _targets.map((t) => t.id).toSet();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Show list for a duration proportional to list length
    final showDuration = Duration(seconds: 2 + _targets.length);
    Future.delayed(showDuration, () {
      if (!mounted) return;
      setState(() => _phase = 'delay');
      // Brief filled delay
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        _shelfShownAt = DateTime.now();
        setState(() => _phase = 'picking');
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onItemTap(MarketItem item) {
    if (_phase != 'picking') return;
    if (_picked.contains(item.id)) return; // Already picked

    _firstTapAt ??= DateTime.now();
    setState(() {
      _picked.add(item.id);
    });

    // Check if elder has picked enough items
    if (_picked.length >= _targetIds.length + 1 ||
        _picked.length >= _shelf.length) {
      _submitResult();
    }
  }

  void _submitResult() {
    if (_phase == 'done') return;
    setState(() => _phase = 'done');

    final now = DateTime.now();
    final initiationMs = _firstTapAt != null && _shelfShownAt != null
        ? _firstTapAt!.difference(_shelfShownAt!).inMilliseconds
        : 3000;
    final movementMs = _firstTapAt != null
        ? now.difference(_firstTapAt!).inMilliseconds
        : 1000;

    widget.game.submit(
      item: widget.item,
      chosenIds: _picked,
      initiationMs: initiationMs,
      movementMs: movementMs,
    );

    Future.delayed(const Duration(milliseconds: 500), widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: _buildPhase(),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case 'showing_list':
        return _buildListPhase();
      case 'delay':
        return _buildDelayPhase();
      case 'picking':
        return _buildPickingPhase();
      case 'done':
        return const Center(
          child: Icon(Icons.check_circle, size: 80, color: AppColors.leafGreen),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildListPhase() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Remember these items:',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: _targets.map((item) => _buildItemCard(item, large: true)).toList(),
        ),
      ],
    );
  }

  Widget _buildDelayPhase() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_top, size: 60, color: AppColors.marigold),
          SizedBox(height: 16),
          Text(
            'Get ready...',
            style: TextStyle(
              fontSize: 22,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickingPhase() {
    return Column(
      children: [
        const Text(
          'Pick the items from your list:',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: _shelf.length,
            itemBuilder: (context, index) {
              final item = _shelf[index];
              final isPicked = _picked.contains(item.id);
              return _buildShelfItem(item, isPicked);
            },
          ),
        ),
        const SizedBox(height: 16),
        // Done button
        ElevatedButton(
          onPressed: _picked.isNotEmpty ? _submitResult : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.terracotta,
            foregroundColor: AppColors.onColor,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Done (${_picked.length} picked)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildShelfItem(MarketItem item, bool isPicked) {
    return GestureDetector(
      onTap: () => _onItemTap(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isPicked
              ? AppColors.leafGreen.withValues(alpha: 0.2)
              : AppColors.raisedSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPicked ? AppColors.leafGreen : AppColors.border,
            width: isPicked ? 3 : 1.5,
          ),
          boxShadow: isPicked
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.iconAsset,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 8),
            Text(
              item.labelKey.replaceFirst('item.', ''),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPicked
                    ? AppColors.leafGreen
                    : AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            if (isPicked)
              const Icon(Icons.check_circle, color: AppColors.leafGreen, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(MarketItem item, {bool large = false}) {
    return Container(
      width: large ? 120 : 90,
      height: large ? 120 : 90,
      decoration: BoxDecoration(
        color: AppColors.raisedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.marigold, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.iconAsset, style: TextStyle(fontSize: large ? 40 : 30)),
          const SizedBox(height: 4),
          Text(
            item.labelKey.replaceFirst('item.', ''),
            style: TextStyle(
              fontSize: large ? 14 : 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
