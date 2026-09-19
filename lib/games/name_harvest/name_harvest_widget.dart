import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_controller.dart';
import '../cognitive_game.dart';
import '../hint/game_hint.dart';
import '../ui/game_chrome.dart';
import 'name_harvest_game.dart';

/// Playable Name the Harvest widget.
///
/// 60-second category fluency task. Shows category prompt, timer ring,
/// and text input for named items (since ASR not yet wired).
/// Items appear as chips as they're entered.
class NameHarvestWidget extends StatefulWidget {
  const NameHarvestWidget({
    super.key,
    required this.game,
    required this.item,
    required this.onComplete,
  });

  final NameHarvestGame game;
  final GameItem item;
  final VoidCallback onComplete;

  @override
  State<NameHarvestWidget> createState() => _NameHarvestWidgetState();
}

class _NameHarvestWidgetState extends State<NameHarvestWidget>
    with SingleTickerProviderStateMixin {
  final List<String> _namedItems = [];
  final TextEditingController _textController = TextEditingController();
  int _remainingSeconds = 60;
  bool _taskComplete = false;
  Timer? _timer;
  DateTime? _startedAt;

  late AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _finishTask();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _textController.text.trim();
    if (text.isEmpty || _taskComplete) return;

    setState(() {
      _namedItems.add(text);
      _textController.clear();
    });
  }

  void _finishTask() {
    if (_taskComplete) return;
    setState(() => _taskComplete = true);

    final now = DateTime.now();
    final totalMs = now.difference(_startedAt!).inMilliseconds;

    widget.game.submit(
      item: widget.item,
      itemsNamed: _namedItems,
      initiationMs: 0,
      movementMs: totalMs,
    );

    Future.delayed(const Duration(milliseconds: 800), widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.instance.currentLanguage;
    final category = widget.item.payload['category'] as String;
    final isCompact = MediaQuery.of(context).size.height < 500;
    final categoryName = AppStrings.harvestCategory(lang, category);
    final promptText = AppStrings.nameAllCategoryPrompt(lang, categoryName);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isCompact ? 6 : 20),
      child: Column(
        children: [
          if (isCompact)
            // Compact Header: timer + prompt side-by-side
            Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _ringController,
                        builder: (context, child) {
                          return CircularProgressIndicator(
                            value: 1.0 - _ringController.value,
                            strokeWidth: 4,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation(
                              _remainingSeconds > 10
                                  ? AppColors.leafGreen
                                  : AppColors.terracotta,
                            ),
                          );
                        },
                      ),
                      Text(
                        '$_remainingSeconds',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _remainingSeconds > 10
                              ? AppColors.primaryText
                              : AppColors.terracotta,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: GamePrompt(
                    promptText,
                    icon: Icons.record_voice_over_rounded,
                    color: AppColors.orchid,
                  ),
                ),
              ],
            )
          else ...[
            // Regular tablet: timer ring on top
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _ringController,
                    builder: (context, child) {
                      return CircularProgressIndicator(
                        value: 1.0 - _ringController.value,
                        strokeWidth: 6,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(
                          _remainingSeconds > 10
                              ? AppColors.leafGreen
                              : AppColors.terracotta,
                        ),
                      );
                    },
                  ),
                  Text(
                    '$_remainingSeconds',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _remainingSeconds > 10
                          ? AppColors.primaryText
                          : AppColors.terracotta,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GamePrompt(
              promptText,
              icon: Icons.record_voice_over_rounded,
              color: AppColors.orchid,
            ),
          ],
          SizedBox(height: isCompact ? 8 : 16),

          // Input area
          if (!_taskComplete)
            Row(
              children: [
                Expanded(
                  child: HintGlow(
                    isAnswer: !_taskComplete && _namedItems.isEmpty,
                    radius: 14,
                    child: TextField(
                      controller: _textController,
                      style: TextStyle(
                          fontSize: isCompact ? 16 : 20, color: AppColors.primaryText),
                      decoration: InputDecoration(
                        hintText: AppStrings.typeAnItem(lang),
                        hintStyle: TextStyle(
                            fontSize: isCompact ? 14 : 18, color: AppColors.secondaryText),
                        filled: true,
                        fillColor: AppColors.raisedSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: AppColors.orchid.withValues(alpha: 0.6), width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 14, vertical: isCompact ? 10 : 16),
                      ),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orchid,
                    shape: const CircleBorder(),
                    padding: EdgeInsets.all(isCompact ? 12 : 16),
                  ),
                  child: Icon(Icons.add_rounded, size: isCompact ? 24 : 30),
                ),
              ],
            ),
          SizedBox(height: isCompact ? 6 : 12),

          // Named items as chips
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _namedItems.asMap().entries.map((entry) {
                  return Chip(
                    avatar: const Icon(Icons.check_circle_rounded, color: AppColors.onColor, size: 20),
                    label: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: isCompact ? 13 : 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onColor,
                      ),
                    ),
                    backgroundColor: AppColors.leafGreen,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 8 : 12, vertical: isCompact ? 4 : 6),
                  );
                }).toList(),
              ),
            ),
          ),

          // Count
          Text(
            AppStrings.itemsNamed(lang, _namedItems.length),
            style: TextStyle(
              fontSize: isCompact ? 14 : 18,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
            ),
          ),

          if (_taskComplete)
            Padding(
              padding: EdgeInsets.only(top: isCompact ? 4 : 12),
              child: Icon(Icons.check_circle_rounded,
                  size: isCompact ? 36 : 50, color: AppColors.leafGreen),
            ),
        ],
      ),
    );
  }
}
