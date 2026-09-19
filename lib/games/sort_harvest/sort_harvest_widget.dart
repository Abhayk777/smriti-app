import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_controller.dart';
import '../../ui/smriti_ui.dart';
import '../cognitive_game.dart';
import '../hint/game_hint.dart';
import '../ui/game_chrome.dart';
import 'sort_harvest_game.dart';

/// Playable Sort the Harvest widget.
///
/// Shows a produce card at top and sorting mats at bottom. Elder drags
/// the card to the correct mat. Rule changes without announcement.
class SortHarvestWidget extends StatefulWidget {
  const SortHarvestWidget({
    super.key,
    required this.game,
    required this.item,
    required this.onComplete,
  });

  final SortHarvestGame game;
  final GameItem item;
  final VoidCallback onComplete;

  @override
  State<SortHarvestWidget> createState() => _SortHarvestWidgetState();
}

class _SortHarvestWidgetState extends State<SortHarvestWidget> {
  DateTime? _shownAt;
  DateTime? _firstTapAt;
  bool _answered = false;

  late final Map<String, String> _card;
  late final List<String> _mats;

  @override
  void initState() {
    super.initState();
    _shownAt = DateTime.now();
    _card = Map<String, String>.from(
        widget.item.payload['card'] as Map<String, Object>);
    _mats = (widget.item.payload['mats'] as List<Object?>).cast<String>();
  }

  void _onMatTap(String mat) {
    if (_answered) return;
    _firstTapAt ??= DateTime.now();
    setState(() => _answered = true);

    final now = DateTime.now();
    final initiationMs =
        _firstTapAt!.difference(_shownAt!).inMilliseconds;
    final movementMs = now.difference(_firstTapAt!).inMilliseconds;

    widget.game.submit(
      item: widget.item,
      chosenMat: mat,
      initiationMs: initiationMs,
      movementMs: movementMs,
    );

    Future.delayed(const Duration(milliseconds: 600), widget.onComplete);
  }

  Color _colorForMat(String mat) {
    const matColors = {
      'vegetable': AppColors.leafGreen,
      'fruit': AppColors.terracotta,
      'grain': AppColors.marigold,
      'red': Color(0xFFE74C3C),
      'green': Color(0xFF27AE60),
      'purple': Color(0xFF8E44AD),
      'yellow': Color(0xFFF1C40F),
      'brown': Color(0xFF795548),
      'white': Color(0xFFECF0F1),
      'small': AppColors.indigo,
      'large': AppColors.terracottaDark,
    };
    return matColors[mat] ?? AppColors.border;
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.height < 500;
    final lang = LocaleController.instance.currentLanguage;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: isCompact ? 8 : 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - (isCompact ? 16 : 32)).clamp(0.0, double.infinity),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GamePrompt(
                  AppStrings.placeItemWhereBelongs(lang),
                  icon: Icons.category_rounded,
                  color: AppColors.bamboo,
                ),
                SizedBox(height: isCompact ? 12 : 26),

                // The item to sort
                _buildCard(isCompact, lang),
                SizedBox(height: isCompact ? 6 : 12),
                Icon(
                  Icons.south_rounded,
                  size: isCompact ? 26 : 38,
                  color: AppColors.bamboo.withValues(alpha: 0.45),
                ),
                SizedBox(height: isCompact ? 6 : 12),

                // The baskets
                if (!_answered)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: isCompact ? 12 : 18,
                    runSpacing: isCompact ? 12 : 18,
                    children: _mats.map((m) => _buildMat(m, isCompact, lang)).toList(),
                  )
                else
                  const Center(
                    child: PopIn(
                      child: Icon(Icons.check_circle_rounded, size: 72, color: AppColors.leafGreen),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _matPhoto = {
    'fruit': 'banana',
    'grain': 'rice',
    'vegetable': 'tomato',
    'pulse': 'dal',
    'dairy': 'milk',
    'pantry': 'tea',
  };

  Widget _buildCard(bool isCompact, String lang) {
    final size = isCompact ? 100.0 : 190.0;
    final rawId = _card['id']?.split('_').first ?? '';
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isCompact ? 16 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ItemPhoto(id: rawId, emoji: _card['emoji'] ?? '🧺', emojiSize: isCompact ? 34 : 60),
          const PhotoScrim(),
          Positioned(
            left: 6,
            right: 6,
            bottom: 8,
            child: Text(
              AppStrings.marketItemName(lang, rawId),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isCompact ? 15 : 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMat(String mat, bool isCompact, String lang) {
    return HintGlow(
      isAnswer: !_answered && mat == widget.item.context['correctMat'],
      radius: isCompact ? 16 : 24,
      child: _buildMatCore(mat, isCompact, lang),
    );
  }

  Widget _buildMatCore(String mat, bool isCompact, String lang) {
    final color = _colorForMat(mat);
    final photo = _matPhoto[mat];
    final w = isCompact ? 108.0 : 160.0;
    final h = isCompact ? 116.0 : 186.0;
    return BouncyTap(
      onTap: () => _onMatTap(mat),
      child: Container(
        width: w,
        height: h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(isCompact ? 16 : 24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: photo == null
                  ? const SizedBox.expand()
                  : SizedBox.expand(child: ItemPhoto(id: photo, emoji: '🧺')),
            ),
            Container(
              width: double.infinity,
              color: color,
              padding: EdgeInsets.symmetric(vertical: isCompact ? 8 : 12, horizontal: 4),
              child: Text(
                AppStrings.harvestMatLabel(lang, mat),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 15 : 19,
                  fontWeight: FontWeight.w800,
                  color: mat == 'white' || mat == 'yellow' || mat == 'grain' ? AppColors.primaryText : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
