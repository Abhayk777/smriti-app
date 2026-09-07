import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../cognitive_game.dart';
import 'my_day_game.dart';

/// Playable My Day widget.
///
/// Two modes:
///   - Ordering: Drag daily events into chronological order
///   - Orientation: Answer questions about day/season/month
class MyDayWidget extends StatefulWidget {
  const MyDayWidget({
    super.key,
    required this.game,
    required this.item,
    required this.onComplete,
  });

  final MyDayGame game;
  final GameItem item;
  final VoidCallback onComplete;

  @override
  State<MyDayWidget> createState() => _MyDayWidgetState();
}

class _MyDayWidgetState extends State<MyDayWidget> {
  DateTime? _shownAt;
  DateTime? _firstTapAt;
  bool _submitted = false;

  late final String _mode;
  late List<Map<String, Object>> _events;

  // Orientation mode
  final _orientationOptions = <String>[];
  String? _orientationAnswer;

  @override
  void initState() {
    super.initState();
    _shownAt = DateTime.now();
    _mode = widget.item.payload['mode'] as String;

    if (_mode == 'ordering') {
      _events = (widget.item.payload['events'] as List<Object?>)
          .cast<Map<String, Object>>();
    } else {
      _setupOrientationOptions();
    }
  }

  void _setupOrientationOptions() {
    final now = DateTime.now();
    final questionId = widget.item.context['questionId'] as String;

    switch (questionId) {
      case 'season':
        _orientationOptions.addAll(['Winter', 'Spring', 'Summer', 'Monsoon', 'Autumn']);
        _orientationAnswer = _currentSeason(now.month);
      case 'day_of_week':
        _orientationOptions.addAll(
            ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']);
        _orientationAnswer = _dayName(now.weekday);
      case 'month':
        _orientationOptions.addAll([
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ]);
        _orientationAnswer = _monthName(now.month);
      case 'after_lunch':
        _orientationOptions.addAll(['Rest', 'Walk', 'Tea', 'Games']);
        _orientationAnswer = 'Rest';
      case 'before_dinner':
        _orientationOptions.addAll(['Evening Tea', 'Walk', 'Prayer', 'Games']);
        _orientationAnswer = 'Evening Tea';
      case 'date':
        // Show nearby dates
        for (var d = now.day - 2; d <= now.day + 2; d++) {
          if (d > 0 && d <= 31) _orientationOptions.add('$d');
        }
        _orientationAnswer = '${now.day}';
    }
  }

  String _currentSeason(int month) {
    // North-East India seasons
    if (month >= 11 || month <= 2) return 'Winter';
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 7) return 'Summer';
    if (month >= 8 && month <= 9) return 'Monsoon';
    return 'Autumn';
  }

  String _dayName(int weekday) {
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday];
  }

  String _monthName(int month) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month];
  }

  void _onReorderComplete() {
    if (_submitted) return;
    _firstTapAt ??= DateTime.now();
    setState(() => _submitted = true);

    final now = DateTime.now();
    final currentOrder = _events.map((e) => e['id'] as String).toList();

    widget.game.submitOrdering(
      item: widget.item,
      chosenOrder: currentOrder,
      initiationMs: _firstTapAt!.difference(_shownAt!).inMilliseconds,
      movementMs: now.difference(_firstTapAt!).inMilliseconds,
    );

    Future.delayed(const Duration(milliseconds: 600), widget.onComplete);
  }

  void _onOrientationAnswer(String answer) {
    if (_submitted) return;
    _firstTapAt ??= DateTime.now();
    setState(() => _submitted = true);

    final now = DateTime.now();
    final correct = answer == _orientationAnswer;

    widget.game.submitOrientation(
      item: widget.item,
      correct: correct,
      initiationMs: _firstTapAt!.difference(_shownAt!).inMilliseconds,
      movementMs: now.difference(_firstTapAt!).inMilliseconds,
    );

    Future.delayed(const Duration(milliseconds: 600), widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: _mode == 'ordering' ? _buildOrderingMode() : _buildOrientationMode(),
    );
  }

  Widget _buildOrderingMode() {
    return Column(
      children: [
        const Text(
          'Put these in the right order — morning to night:',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ReorderableListView(
            // ignore: deprecated_member_use
            onReorder: (oldIndex, newIndex) {
              _firstTapAt ??= DateTime.now();
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _events.removeAt(oldIndex);
                _events.insert(newIndex, item);
              });
            },
            children: _events.asMap().entries.map((entry) {
              final event = entry.value;
              return _buildEventTile(event, key: ValueKey(event['id']));
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        if (!_submitted)
          ElevatedButton(
            onPressed: _onReorderComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracotta,
              foregroundColor: AppColors.onColor,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _buildEventTile(Map<String, Object> event, {Key? key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.raisedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Text(
            (event['icon'] as String?) ?? '📌',
            style: const TextStyle(fontSize: 30),
          ),
          const SizedBox(width: 16),
          Text(
            (event['label'] as String?) ?? '',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const Spacer(),
          const Icon(Icons.drag_handle, color: AppColors.ghostHand, size: 28),
        ],
      ),
    );
  }

  Widget _buildOrientationMode() {
    final question =
        (widget.item.payload['question'] as Map<String, Object>?) ?? {};
    final questionText =
        question['question'] as String? ?? 'What day is it today?';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.calendar_today, size: 50, color: AppColors.marigold),
        const SizedBox(height: 20),
        Text(
          questionText,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        if (!_submitted)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _orientationOptions.map((option) {
              return GestureDetector(
                onTap: () => _onOrientationAnswer(option),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 100),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.raisedSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          )
        else
          const Icon(Icons.check_circle, size: 60, color: AppColors.leafGreen),
      ],
    );
  }
}
