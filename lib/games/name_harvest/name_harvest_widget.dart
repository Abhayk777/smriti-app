import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../cognitive_game.dart';
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

  String _categoryLabel(String category) {
    const labels = {
      'vegetables': 'vegetables',
      'fruits': 'fruits',
      'animals': 'animals',
      'things_in_kitchen': 'things in the kitchen',
      'things_in_market': 'things at the market',
    };
    return labels[category] ?? category;
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.item.payload['category'] as String;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Timer ring
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
          const SizedBox(height: 20),

          // Prompt
          Text(
            'Name all the ${_categoryLabel(category)} you can think of:',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Input area
          if (!_taskComplete)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(
                        fontSize: 20, color: AppColors.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Type an item...',
                      hintStyle: const TextStyle(
                          fontSize: 18, color: AppColors.secondaryText),
                      filled: true,
                      fillColor: AppColors.raisedSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppColors.border, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: AppColors.onColor,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Icon(Icons.add, size: 28),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Named items as chips
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _namedItems.asMap().entries.map((entry) {
                  return Chip(
                    label: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onColor,
                      ),
                    ),
                    backgroundColor: AppColors.leafGreen,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  );
                }).toList(),
              ),
            ),
          ),

          // Count
          Text(
            '${_namedItems.length} items named',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
            ),
          ),

          if (_taskComplete)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Icon(Icons.check_circle,
                  size: 50, color: AppColors.leafGreen),
            ),
        ],
      ),
    );
  }
}
