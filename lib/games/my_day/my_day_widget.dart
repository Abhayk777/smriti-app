import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_controller.dart';
import '../../ui/smriti_ui.dart';
import '../cognitive_game.dart';
import '../hint/game_hint.dart';
import '../ui/game_chrome.dart';
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

  void _moveUp(int index) {
    if (index <= 0 || _submitted) return;
    _firstTapAt ??= DateTime.now();
    setState(() {
      final item = _events.removeAt(index);
      _events.insert(index - 1, item);
    });
  }

  void _moveDown(int index) {
    if (index >= _events.length - 1 || _submitted) return;
    _firstTapAt ??= DateTime.now();
    setState(() {
      final item = _events.removeAt(index);
      _events.insert(index + 1, item);
    });
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

  /// The event that belongs at the first out-of-place position, so the hint
  /// (and the tutorial) can point at the row to move up.
  String? _hintEventId() {
    final correct = (widget.item.payload['correctOrder'] as List<Object?>?)?.cast<String>();
    if (correct == null) return null;
    final current = _events.map((e) => e['id'] as String).toList();
    for (var i = 0; i < current.length && i < correct.length; i++) {
      if (current[i] != correct[i]) return correct[i];
    }
    return null;
  }

  Widget _buildOrderingMode(bool isCompact) {
    final lang = LocaleController.instance.currentLanguage;
    return Column(
      children: [
        GamePrompt(
          AppStrings.putInOrderMorningToNight(lang),
          icon: Icons.wb_twilight_rounded,
          color: AppColors.riverTeal,
        ),
        SizedBox(height: isCompact ? 8 : 14),
        Expanded(
          child: ReorderableListView(
            buildDefaultDragHandles: false,
            // ignore: deprecated_member_use
            onReorder: (oldIndex, newIndex) {
              if (_submitted) return;
              _firstTapAt ??= DateTime.now();
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _events.removeAt(oldIndex);
                _events.insert(newIndex, item);
              });
            },
            children: _events.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              return _buildEventTile(
                event,
                index: index,
                totalCount: _events.length,
                isCompact: isCompact,
                key: ValueKey(event['id']),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: isCompact ? 8 : 14),
        if (!_submitted)
          SizedBox(
            width: double.infinity,
            height: isCompact ? 52 : 62,
            child: ElevatedButton.icon(
              onPressed: _onReorderComplete,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 26),
              label: Text(
                AppStrings.done(lang),
                style: TextStyle(fontSize: isCompact ? 18 : 21, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.leafGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          )
        else
          PopIn(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, size: 36, color: AppColors.leafGreen),
                const SizedBox(width: 10),
                Text(
                  AppStrings.wellDone(lang),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.leafGreenDark,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEventTile(
    Map<String, Object> event, {
    required int index,
    required int totalCount,
    bool isCompact = false,
    Key? key,
  }) {
    final lang = LocaleController.instance.currentLanguage;
    final rawLabel = (event['label'] as String?) ?? '';
    final localizedLabel = AppStrings.routineLabel(lang, rawLabel);

    Widget moveButton(String tooltip, IconData icon, VoidCallback? onPressed) {
      return IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: isCompact ? 22 : 26,
        style: IconButton.styleFrom(
          minimumSize: Size(isCompact ? 40 : 46, isCompact ? 40 : 46),
          backgroundColor: AppColors.marigold.withValues(alpha: 0.22),
          foregroundColor: AppColors.marigoldDark,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: AppColors.secondaryText.withValues(alpha: 0.25),
        ),
      );
    }

    return HintGlow(
      key: key,
      isAnswer: !_submitted && event['id'] == _hintEventId(),
      radius: 22,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: isCompact ? 4 : 7),
        padding: EdgeInsets.fromLTRB(isCompact ? 10 : 14, isCompact ? 8 : 11, 6, isCompact ? 8 : 11),
        decoration: BoxDecoration(
          color: AppColors.raisedSurface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.riverTeal.withValues(alpha: 0.14),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: isCompact ? 28 : 34,
              height: isCompact ? 28 : 34,
              decoration: BoxDecoration(
                color: AppColors.riverTeal.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: isCompact ? 14 : 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.riverTealDark,
                ),
              ),
            ),
            SizedBox(width: isCompact ? 10 : 12),
            RoutinePhoto(
              id: (event['id'] as String?) ?? '',
              emoji: (event['icon'] as String?) ?? '📌',
              label: rawLabel,
              size: isCompact ? 44 : 54,
            ),
            SizedBox(width: isCompact ? 10 : 14),
            Expanded(
              child: Text(
                localizedLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 17 : 20,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
            ),
            if (!_submitted) ...[
              moveButton('Move Up', Icons.arrow_upward_rounded, index > 0 ? () => _moveUp(index) : null),
              const SizedBox(width: 4),
              moveButton('Move Down', Icons.arrow_downward_rounded,
                  index < totalCount - 1 ? () => _moveDown(index) : null),
            ],
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: AppColors.ghostHand.withValues(alpha: 0.7),
                  size: isCompact ? 22 : 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrientationMode(bool isCompact) {
    final lang = LocaleController.instance.currentLanguage;
    final question =
        (widget.item.payload['question'] as Map<String, Object>?) ?? {};
    final questionId = (widget.item.context['questionId'] as String?) ??
        (question['id'] as String?) ?? '';
    final defaultQuestionText =
        question['question'] as String? ?? 'What day is it today?';
    final questionText = AppStrings.orientationQuestion(
      lang,
      questionId,
      defaultText: defaultQuestionText,
    );

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
                final isCorrect = option == _orientationAnswer;
                return HintGlow(
                  isAnswer: !_submitted && isCorrect,
                  radius: 18,
                  child: BouncyTap(
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
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: AppColors.terracottaDeep.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: Text(
                        AppStrings.displayOrientationOption(lang, questionId, option),
                        style: TextStyle(
                          fontSize: isCompact ? 18 : 21,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
