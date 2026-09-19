import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_controller.dart';
import '../../ui/smriti_ui.dart';
import '../cognitive_game.dart';
import 'weaving_game.dart';
import 'woven_strip.dart';

/// Playable Weaving Patterns widget.
///
/// Shows a Manipuri textile pattern at top and four options below.
/// Elder picks the matching one. Patterns are procedurally generated
/// using colored blocks in various arrangements.
class WeavingWidget extends StatefulWidget {
  const WeavingWidget({
    super.key,
    required this.game,
    required this.item,
    required this.onComplete,
  });

  final WeavingGame game;
  final GameItem item;
  final VoidCallback onComplete;

  @override
  State<WeavingWidget> createState() => _WeavingWidgetState();
}

class _WeavingWidgetState extends State<WeavingWidget> {
  DateTime? _shownAt;
  DateTime? _firstTapAt;
  bool _answered = false;

  late final List<int> _targetPattern;
  late final String _patternType;
  late final List<Map<String, Object>> _options;
  late final List<int> _colors;

  @override
  void initState() {
    super.initState();
    _shownAt = DateTime.now();
    _targetPattern = (widget.item.payload['targetPattern'] as List<Object?>)
        .cast<int>();
    _patternType = widget.item.payload['patternType'] as String;
    _options = (widget.item.payload['options'] as List<Object?>)
        .cast<Map<String, Object>>();
    _colors = (widget.item.payload['colors'] as List<Object?>).cast<int>();
  }

  void _onOptionTap(String optionId) {
    if (_answered) return;
    _firstTapAt ??= DateTime.now();
    setState(() => _answered = true);

    final now = DateTime.now();
    widget.game.submit(
      item: widget.item,
      chosenId: optionId,
      initiationMs: _firstTapAt!.difference(_shownAt!).inMilliseconds,
      movementMs: now.difference(_firstTapAt!).inMilliseconds,
    );

    Future.delayed(const Duration(milliseconds: 600), widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.instance.currentLanguage;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            AppStrings.whichPatternMatches(lang),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 24),

          // Target pattern (large)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.raisedSurface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.marigold.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildPattern(_targetPattern, size: 36),
            ),
          ),
          const SizedBox(height: 24),

          // Options
          if (!_answered)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: Column(
                    children: _options.map((option) {
                      final optionPattern = (option['pattern'] as List<Object?>)
                          .cast<int>();
                      final optionId = option['id'] as String;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: BouncyTap(
                          onTap: () => _onOptionTap(optionId),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth.clamp(0, 460),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.raisedSurface,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.terracottaDeep
                                        .withValues(alpha: 0.10),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _buildPattern(optionPattern, size: 40),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 60,
                  color: AppColors.leafGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPattern(List<int> pattern, {double size = 30}) {
    return WovenStrip(pattern: pattern, colors: _colors, type: _patternType, cell: size);
  }
}
