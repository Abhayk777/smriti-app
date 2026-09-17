import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../ui/smriti_ui.dart';
import '../cognitive_game.dart';
import 'my_day_game.dart';

/// Soft tints that give each card its own colour.
const _tints = [
  Color(0xFFFBE3D6), // terracotta
  Color(0xFFDDE6F2), // hill blue
  Color(0xFFF7EACB), // mustard
  Color(0xFFDDEBDF), // tea green
  Color(0xFFEADFF0), // orchid
  Color(0xFFD9ECEC), // river
];

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
      case 'before_dinner':
        // Answer and choices come from the elder's own routine.
        _orientationOptions.addAll(
            (widget.item.payload['options'] as List<Object?>? ?? const [])
                .cast<String>());
        _orientationAnswer = widget.item.payload['answer'] as String?;
      case 'date':
        // Show nearby dates; the spread narrows as the level rises
        // (docs/PROGRESSION_PLAN.md §5.3), falling back to the old fixed
        // window of 2 for items generated before this existed.
        final spread = widget.item.payload['dateOptionSpread'] as int? ?? 2;
        for (var d = now.day - spread; d <= now.day + spread; d++) {
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
    final isCompact = MediaQuery.of(context).size.height < 500;
    return Padding(
      padding: EdgeInsets.all(isCompact ? 10 : 20),
      child: _mode == 'ordering' ? _buildOrderingMode(isCompact) : _buildOrientationMode(isCompact),
    );
  }

  Widget _buildOrderingMode(bool isCompact) {
    return Column(
      children: [
        Text(
          'Put these in order, from morning to night:',
          style: TextStyle(
            fontSize: isCompact ? 17 : 22,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        SizedBox(height: isCompact ? 8 : 20),
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
              return _buildEventTile(event, isCompact: isCompact, key: ValueKey(event['id']));
            }).toList(),
          ),
        ),
        SizedBox(height: isCompact ? 8 : 16),
        if (!_submitted)
          ElevatedButton(
            onPressed: _onReorderComplete,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 32 : 48,
                vertical: isCompact ? 12 : 18,
              ),
            ),
            child: Text(
              'Done',
              style: TextStyle(
                fontSize: isCompact ? 17 : 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEventTile(Map<String, Object> event, {bool isCompact = false, Key? key}) {
    return Container(
      key: key,
      margin: EdgeInsets.symmetric(vertical: isCompact ? 3 : 6),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: isCompact ? 8 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.raisedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Text(
            (event['icon'] as String?) ?? '📌',
            style: TextStyle(fontSize: isCompact ? 22 : 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              (event['label'] as String?) ?? '',
              style: TextStyle(
                fontSize: isCompact ? 17 : 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.drag_handle_rounded, color: AppColors.ghostHand, size: isCompact ? 24 : 30),
        ],
      ),
    );
  }

  Widget _buildOrientationMode(bool isCompact) {
    final question =
        (widget.item.payload['question'] as Map<String, Object>?) ?? {};
    final questionText =
        question['question'] as String? ?? 'What day is it today?';

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_rounded, size: isCompact ? 36 : 52, color: AppColors.marigoldDark),
          SizedBox(height: isCompact ? 10 : 20),
          Text(
            questionText,
            style: TextStyle(
              fontSize: isCompact ? 20 : 26,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isCompact ? 14 : 30),
          if (!_submitted)
            Wrap(
              spacing: isCompact ? 8 : 12,
              runSpacing: isCompact ? 8 : 12,
              alignment: WrapAlignment.center,
              children: _orientationOptions.map((option) {
                final tint = _tints[_orientationOptions.indexOf(option) % _tints.length];
                return BouncyTap(
                  onTap: () => _onOrientationAnswer(option),
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: isCompact ? 96 : 120,
                      minHeight: isCompact ? 52 : 64,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 16 : 22,
                      vertical: isCompact ? 12 : 16,
                    ),
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: isCompact ? 18 : 21,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }).toList(),
            )
          else
            PopIn(child: Icon(Icons.check_circle_rounded, size: isCompact ? 44 : 64, color: AppColors.leafGreen)),
        ],
      ),
    );
  }
}
