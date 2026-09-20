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

  /// The colour a basket stands for. For the colour rule this *is* the
  /// answer, so it has to be the real colour of the produce.
  static const _matColors = {
    'vegetable': AppColors.leafGreen,
    'fruit': AppColors.terracotta,
    'grain': AppColors.marigold,
    'red': Color(0xFFD0432F),
    'green': Color(0xFF2F9E52),
    'purple': Color(0xFF7B4A9C),
    'yellow': Color(0xFFE8B23A),
    'brown': Color(0xFF8A5A3B),
    'white': Color(0xFFF2EDE3),
    'small': AppColors.indigo,
    'large': AppColors.riverTeal,
  };

  /// A photo that stands for a whole kind of produce.
  static const _matPhoto = {
    'fruit': 'banana',
    'grain': 'rice',
    'vegetable': 'tomato',
    'pulse': 'dal',
    'dairy': 'milk',
    'pantry': 'tea',
  };

  Color _colorForMat(String mat) => _matColors[mat] ?? AppColors.bamboo;

  /// Ink that stays readable on [_colorForMat].
  static Color _inkOn(Color c) =>
      c.computeLuminance() > 0.6 ? AppColors.primaryText : Colors.white;

  String get _rule => (widget.item.payload['dimension'] as String?) ?? 'type';

  bool get _ruleChanged => widget.item.payload['ruleChanged'] as bool? ?? false;

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.instance.currentLanguage;

    return LayoutBuilder(
      builder: (context, c) {
        // Everything is sized from the room actually available, so three or
        // four baskets never run off the bottom of a small phone.
        final h = c.maxHeight;
        final compact = h < 560;
        final perRow = _mats.length <= 2 ? _mats.length : 2;
        final rows = (_mats.length / perRow).ceil();
        final gap = compact ? 10.0 : 16.0;

        final chrome = (compact ? 120.0 : 170.0) + (_dimensionsInPlay.length > 1 ? 58 : 0);
        final forBaskets = (h - chrome) * (rows == 1 ? 0.46 : 0.62);
        final matH = (forBaskets / rows - gap).clamp(86.0, 176.0);
        final matW = (matH * 0.88).clamp(96.0, 160.0);
        final cardSide = (h - chrome - forBaskets).clamp(84.0, 190.0);

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 6 : 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: (h - (compact ? 12 : 24)).clamp(0.0, double.infinity)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GamePrompt(
                  AppStrings.placeItemWhereBelongs(lang),
                  icon: Icons.category_rounded,
                  color: AppColors.bamboo,
                ),

                // What the baskets stand for right now. Pictures, not words,
                // so it reads the same in every language.
                if (_dimensionsInPlay.length > 1) ...[
                  SizedBox(height: compact ? 8 : 12),
                  _buildRuleStrip(compact),
                ],
                SizedBox(height: compact ? 10 : 18),

                // The item to sort
                _buildCard(cardSide, lang),
                SizedBox(height: compact ? 2 : 6),
                Icon(
                  Icons.south_rounded,
                  size: compact ? 22 : 32,
                  color: AppColors.bamboo.withValues(alpha: 0.45),
                ),
                SizedBox(height: compact ? 2 : 6),

                // The baskets
                if (!_answered)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final m in _mats)
                        SizedBox(
                          width: matW,
                          height: matH,
                          child: _buildMat(m, compact, lang),
                        ),
                    ],
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
        );
      },
    );
  }

  /// The rules unlocked at this level, in the order they are introduced.
  List<String> get _dimensionsInPlay {
    final count = SortHarvestGame.dimensionCountFor(widget.item.difficulty);
    return SortHarvestGame.dimensions.take(count).toList();
  }

  static const _ruleIcons = {
    'type': Icons.eco_rounded,
    'colour': Icons.palette_rounded,
    'size': Icons.straighten_rounded,
  };

  /// Three quiet chips, one per rule, with the one in play lit. When the rule
  /// has just moved the lit chip breathes, so the change is noticed without a
  /// word of warning text.
  Widget _buildRuleStrip(bool isCompact) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final d in _dimensionsInPlay)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: _RuleChip(
              icon: _ruleIcons[d] ?? Icons.help_outline_rounded,
              active: d == _rule,
              pulse: d == _rule && _ruleChanged,
              compact: isCompact,
            ),
          ),
      ],
    );
  }

  Widget _buildCard(double size, String lang) {
    final rawId = _card['id']?.split('_').first ?? '';
    final small = size < 130;
    return PopIn(
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(small ? 20 : 28),
          boxShadow: [
            BoxShadow(
              color: AppColors.bamboo.withValues(alpha: 0.3),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ItemPhoto(id: rawId, emoji: _card['emoji'] ?? '🧺', emojiSize: small ? 34 : 60),
            const PhotoScrim(),
            Positioned(
              left: 6,
              right: 6,
              bottom: 10,
              child: Text(
                AppStrings.marketItemName(lang, rawId),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: small ? 15 : 21,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMat(String mat, bool isCompact, String lang) {
    return HintGlow(
      isAnswer: !_answered && mat == widget.item.context['correctMat'],
      radius: isCompact ? 18 : 26,
      child: _buildMatCore(mat, isCompact, lang),
    );
  }

  Widget _buildMatCore(String mat, bool isCompact, String lang) {
    final color = _colorForMat(mat);

    return BouncyTap(
      onTap: () => _onMatTap(mat),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(isCompact ? 18 : 26),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.38),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(child: _buildMatFace(mat, color)),
            Container(
              width: double.infinity,
              color: color,
              padding: EdgeInsets.symmetric(vertical: isCompact ? 6 : 10, horizontal: 4),
              child: Text(
                AppStrings.harvestMatLabel(lang, mat),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 15 : 18,
                  fontWeight: FontWeight.w800,
                  color: _inkOn(color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// What a basket shows above its name, which depends on what is being
  /// matched: a photo for a kind of produce, the colour itself for a colour,
  /// and a big or small shape for a size.
  Widget _buildMatFace(String mat, Color color) {
    switch (_rule) {
      case 'colour':
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: color),
            Center(
              child: FractionallySizedBox(
                widthFactor: 0.52,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.35, -0.4),
                        colors: [
                          Color.lerp(color, Colors.white, 0.45)!,
                          color,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case 'size':
        final big = mat == 'large';
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: Color.lerp(color, Colors.white, 0.12)!),
            Center(
              child: FractionallySizedBox(
                widthFactor: big ? 0.78 : 0.34,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      default:
        final photo = _matPhoto[mat];
        if (photo == null) {
          return ColoredBox(
            color: color,
            child: Icon(Icons.shopping_basket_rounded, color: _inkOn(color), size: 40),
          );
        }
        return ItemPhoto(id: photo, emoji: '🧺', emojiSize: 30);
    }
  }
}

/// One rule in the strip above the card: an icon in a soft disc, lit while
/// that rule is the one in play.
class _RuleChip extends StatefulWidget {
  const _RuleChip({
    required this.icon,
    required this.active,
    required this.pulse,
    required this.compact,
  });

  final IconData icon;
  final bool active;
  final bool pulse;
  final bool compact;

  @override
  State<_RuleChip> createState() => _RuleChipState();
}

class _RuleChipState extends State<_RuleChip> with SingleTickerProviderStateMixin {
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _breathe.repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still && _breathe.isAnimating) _breathe.stop();
    final size = widget.compact ? 40.0 : 50.0;

    return AnimatedBuilder(
      animation: _breathe,
      builder: (context, _) {
        final t = widget.pulse && !still ? Curves.easeInOut.transform(_breathe.value) : 0.0;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.active
                ? AppColors.bamboo
                : AppColors.bamboo.withValues(alpha: 0.13),
            boxShadow: widget.active
                ? [
                    BoxShadow(
                      color: AppColors.bamboo.withValues(alpha: 0.35 + 0.35 * t),
                      blurRadius: 10 + 12 * t,
                      spreadRadius: t * 3,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            widget.icon,
            size: size * 0.52,
            color: widget.active ? Colors.white : AppColors.bamboo.withValues(alpha: 0.75),
          ),
        );
      },
    );
  }
}
