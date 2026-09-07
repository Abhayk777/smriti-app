import 'package:flutter/material.dart';

import '../../app_colors.dart';
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Instruction (no mention of current rule — it's unsignalled!)
          const Text(
            'Place this item where it belongs:',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 24),

          // Card to sort
          _buildCard(),
          const SizedBox(height: 40),

          // Sorting mats
          if (!_answered)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _mats.map(_buildMat).toList(),
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Icon(Icons.check_circle,
                    size: 60, color: AppColors.leafGreen),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.raisedSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.marigold, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _card['emoji'] ?? '🌿',
            style: const TextStyle(fontSize: 50),
          ),
          const SizedBox(height: 8),
          Text(
            _card['id']?.split('_').first ?? '',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMat(String mat) {
    final color = _colorForMat(mat);
    return GestureDetector(
      onTap: () => _onMatTap(mat),
      child: Container(
        width: 130,
        height: 160,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 2.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.place, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              mat.replaceAll('_', ' '),
              style: TextStyle(
                fontSize: 16,
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
