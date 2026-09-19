import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_controller.dart';
import '../../ui/smriti_ui.dart';
import '../cognitive_game.dart';
import '../hint/game_hint.dart';
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

    // Show list for a duration set by the level (docs/PROGRESSION_PLAN.md
    // §5.3), falling back to the old fixed formula for items generated
    // before this existed.
    final studySeconds =
        widget.item.payload['studySeconds'] as int? ?? 2 + _targets.length;
    final delaySeconds = widget.item.payload['delaySeconds'] as int? ?? 2;
    Future.delayed(Duration(seconds: studySeconds), () {
      if (!mounted) return;
      setState(() => _phase = 'delay');
      // Brief filled delay
      Future.delayed(Duration(seconds: delaySeconds), () {
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
    final lang = LocaleController.instance.currentLanguage;
    return Padding(
      padding: EdgeInsets.all(isCompact ? 8 : 20),
      child: _buildPhase(isCompact, lang),
    );
  }

  Widget _buildPhase(bool isCompact, String lang) {
    switch (_phase) {
      case 'showing_list':
        return _buildListPhase(isCompact, lang);
      case 'delay':
        return _buildDelayPhase(lang);
      case 'picking':
        return _buildPickingPhase(isCompact, lang);
      case 'done':
        return const Center(
          child: Icon(Icons.check_circle_rounded, size: 80, color: AppColors.leafGreen),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildListPhase(bool isCompact, String lang) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppStrings.rememberTheseItems(lang),
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
            children: _targets.map((item) => _buildItemCard(item, lang, large: !isCompact)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDelayPhase(String lang) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_top_rounded, size: 64, color: AppColors.marigoldDark),
          const SizedBox(height: 16),
          Text(
            AppStrings.getReady(lang),
            style: const TextStyle(
              fontSize: 22,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickingPhase(bool isCompact, String lang) {
    return Column(
      children: [
        Text(
          AppStrings.pickItemsFromList(lang),
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
              return _buildShelfItem(item, isPicked, lang);
            },
          ),
        ),
        // Finish picking button
        Padding(
          padding: EdgeInsets.symmetric(vertical: isCompact ? 4 : 8),
          child: ElevatedButton(
            onPressed: _submitResult,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.marigold,
              foregroundColor: AppColors.primaryText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 32 : 48,
                vertical: isCompact ? 10 : 16,
              ),
            ),
            child: Text(
              AppStrings.done(lang),
              style: TextStyle(
                fontSize: isCompact ? 17 : 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShelfItem(MarketItem item, bool isPicked, String lang) {
    final isUnpickedTarget = !isPicked && _targetIds.contains(item.id);
    return HintGlow(
      isAnswer: isUnpickedTarget,
      radius: 20,
      child: BouncyTap(
        onTap: () => _onItemTap(item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isPicked
                ? Border.all(color: AppColors.leafGreen, width: 4)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ItemPhoto(id: item.id, emoji: item.iconAsset),
              const PhotoScrim(),
              if (isPicked)
                ColoredBox(color: AppColors.leafGreen.withValues(alpha: 0.32)),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  AppStrings.marketItemName(lang, item.id),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPicked)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: PopIn(
                    child: Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 30),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(MarketItem item, String lang, {bool large = false}) {
    final side = large ? 140.0 : 108.0;
    return PopIn(
      child: Container(
        width: side,
        height: side,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ItemPhoto(id: item.id, emoji: item.iconAsset),
            const PhotoScrim(),
            Positioned(
              left: 6,
              right: 6,
              bottom: 8,
              child: Text(
                AppStrings.marketItemName(lang, item.id),
                style: TextStyle(
                  fontSize: large ? 19 : 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
