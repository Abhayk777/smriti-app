import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../ui/smriti_ui.dart';
import '../cognitive_game.dart';
import 'market_basket_game.dart';

/// Soft tints that give each card its own colour.
const _tints = [
  Color(0xFFFBE3D6), // terracotta
  Color(0xFFDDE6F2), // hill blue
  Color(0xFFF7EACB), // mustard
  Color(0xFFDDEBDF), // tea green
  Color(0xFFEADFF0), // orchid
  Color(0xFFD9ECEC), // river
];

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
    final isCompact = MediaQuery.of(context).size.height < 500;
    return Padding(
      padding: EdgeInsets.all(isCompact ? 8 : 20),
      child: _buildPhase(isCompact),
    );
  }

  Widget _buildPhase(bool isCompact) {
    switch (_phase) {
      case 'showing_list':
        return _buildListPhase(isCompact);
      case 'delay':
        return _buildDelayPhase();
      case 'picking':
        return _buildPickingPhase(isCompact);
      case 'done':
        return const Center(
          child: Icon(Icons.check_circle_rounded, size: 80, color: AppColors.leafGreen),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildListPhase(bool isCompact) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Remember these items:',
            style: TextStyle(
              fontSize: isCompact ? 18 : 24,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(height: isCompact ? 12 : 30),
          Wrap(
            spacing: isCompact ? 12 : 20,
            runSpacing: isCompact ? 12 : 20,
            alignment: WrapAlignment.center,
            children: _targets.map((item) => _buildItemCard(item, large: !isCompact)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDelayPhase() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_top_rounded, size: 64, color: AppColors.marigoldDark),
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

  Widget _buildPickingPhase(bool isCompact) {
    return Column(
      children: [
        Text(
          'Pick the items from your list:',
          style: TextStyle(
            fontSize: isCompact ? 16 : 22,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        SizedBox(height: isCompact ? 8 : 20),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: isCompact ? 150 : 180,
              mainAxisExtent: isCompact ? 112 : 140,
              crossAxisSpacing: isCompact ? 10 : 14,
              mainAxisSpacing: isCompact ? 10 : 14,
            ),
            itemCount: _shelf.length,
            itemBuilder: (context, index) {
              final item = _shelf[index];
              final isPicked = _picked.contains(item.id);
              return _buildShelfItem(item, isPicked);
            },
          ),
        ),
        SizedBox(height: isCompact ? 8 : 16),
        // Done button
        ElevatedButton(
          onPressed: _picked.isNotEmpty ? _submitResult : null,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 28 : 44,
              vertical: isCompact ? 12 : 18,
            ),
          ),
          child: Text(
            'Done (${_picked.length} picked)',
            style: TextStyle(
              fontSize: isCompact ? 17 : 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShelfItem(MarketItem item, bool isPicked) {
    final tint = _tints[_shelf.indexOf(item) % _tints.length];
    return BouncyTap(
      onTap: () => _onItemTap(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isPicked
              ? AppColors.leafGreen.withValues(alpha: 0.25)
              : tint,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPicked ? AppColors.leafGreen : AppColors.border,
            width: isPicked ? 3 : 1.5,
          ),
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
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isPicked
                    ? AppColors.leafGreenDark
                    : AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isPicked)
              const PopIn(
                child: Icon(Icons.check_circle_rounded, color: AppColors.leafGreen, size: 26),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(MarketItem item, {bool large = false}) {
    return PopIn(
      child: Container(
      width: large ? 130 : 100,
      height: large ? 130 : 100,
      decoration: BoxDecoration(
        color: _tints[_targets.indexOf(item) % _tints.length],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.marigold, width: 2.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.iconAsset, style: TextStyle(fontSize: large ? 40 : 30)),
          const SizedBox(height: 4),
          Text(
            item.labelKey.replaceFirst('item.', ''),
            style: TextStyle(
              fontSize: large ? 17 : 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      ),
    );
  }
}
