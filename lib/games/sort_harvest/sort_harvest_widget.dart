import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_controller.dart';
import '../../ui/smriti_ui.dart';
import '../cognitive_game.dart';
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

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isCompact ? 8 : 20),
      child: Column(
        children: [
          // Instruction
          Text(
            AppStrings.placeItemWhereBelongs(lang),
            style: TextStyle(
              fontSize: isCompact ? 18 : 22,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(height: isCompact ? 10 : 24),

          // Card to sort
          _buildCard(isCompact, lang),
          SizedBox(height: isCompact ? 14 : 32),

          // Sorting mats
          if (!_answered)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: isCompact ? 12 : 20,
              runSpacing: isCompact ? 12 : 20,
              children: _mats.map((m) => _buildMat(m, isCompact, lang)).toList(),
            )
          else
            const Center(
              child: PopIn(
                child: Icon(Icons.check_circle_rounded,
                    size: 64, color: AppColors.leafGreen),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(bool isCompact, String lang) {
    final size = isCompact ? 84.0 : 140.0;
    final rawId = _card['id']?.split('_').first ?? '';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.raisedSurface,
        borderRadius: BorderRadius.circular(isCompact ? 14 : 20),
        border: Border.all(color: AppColors.marigold, width: isCompact ? 2 : 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _card['emoji'] ?? '🧺',
            style: TextStyle(fontSize: isCompact ? 34 : 60),
          ),
          SizedBox(height: isCompact ? 2 : 4),
          Text(
            AppStrings.marketItemName(lang, rawId),
            style: TextStyle(
              fontSize: isCompact ? 13 : 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMat(String mat, bool isCompact, String lang) {
    final color = _colorForMat(mat);
    return BouncyTap(
      onTap: () => _onMatTap(mat),
      child: Container(
        width: isCompact ? 96 : 130,
        height: isCompact ? 104 : 150,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(isCompact ? 14 : 20),
          border: Border.all(color: color, width: isCompact ? 2 : 2.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isCompact ? 36 : 50,
              height: isCompact ? 36 : 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.place_rounded, color: color, size: isCompact ? 20 : 30),
            ),
            SizedBox(height: isCompact ? 6 : 12),
            Text(
              AppStrings.harvestMatLabel(lang, mat),
              style: TextStyle(
                fontSize: isCompact ? 13 : 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
