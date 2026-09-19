import 'dart:async';

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/db/database.dart';
import '../core/i18n/app_strings.dart';
import '../core/i18n/locale_controller.dart';
import '../core/repo/content_repo.dart';
import '../core/sync/sync_engine.dart';
import '../ui/smriti_ui.dart';

/// Shows the elder's daily routine as a warm timeline.
///
/// Reads `RoutineItems` from local SQLite: only the routine the caregiver
/// set on the web app, never placeholder data. Until one arrives, a gentle
/// "will be updated soon" message is shown instead.
/// Highlights the current / next item. Past items are dimmed.
/// No medication items are shown here; those live in MedicineScreen.
class MyDayScreen extends StatefulWidget {
  const MyDayScreen({super.key, this.syncInBackground = true});

  final bool syncInBackground;

  @override
  State<MyDayScreen> createState() => _MyDayScreenState();
}

class _MyDayScreenState extends State<MyDayScreen> {
  final ContentRepo _repo = ContentRepo(appDatabase);
  StreamSubscription<List<RoutineItem>>? _routineSub;
  List<RoutineItem> _items = [];
  bool _loading = true;
  late DateTime _now;
  late int _nowMin; // minutes from midnight
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _nowMin = _now.hour * 60 + _now.minute;
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
        _nowMin = _now.hour * 60 + _now.minute;
      });
    });
    _routineSub = _repo.watchRoutineItems().listen((items) {
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    });
    // Pull the latest routine in the background; the subscription above
    // redraws the timeline whenever a sync (this one or any other) lands.
    if (widget.syncInBackground) {
      unawaited(SyncEngine.defaultInstance.run(trigger: SyncTrigger.manual));
    }
  }

  @override
  void dispose() {
    _routineSub?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  String _formatTime(int min) {
    final h = min ~/ 60;
    final m = min % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$dh:${m.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final lang = LocaleController.instance.currentLanguage;
        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          body: SafeArea(
            child: Column(
              children: [
                ScreenHeader(
      image: 'game_myday.jpg',
                  title: AppStrings.myDay(lang),
                  subtitle: _dateString(lang),
                  icon: Icons.wb_sunny_rounded,
                  color: AppColors.marigoldDark,
                ),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.marigold),
                        )
                      : _items.isEmpty
                          ? _buildEmpty(lang)
                          : _buildTimeline(lang),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(String lang) {
    return EmptyState(
      icon: Icons.event_note_rounded,
      color: AppColors.marigoldDark,
      title: AppStrings.routineEmptyTitle(lang),
      message: AppStrings.routineEmptyMessage(lang),
    );
  }

  Widget _buildTimeline(String lang) {
    // Find the "active" index: first item whose time >= now, or last
    int activeIndex = _items.length - 1;
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].timeMin >= _nowMin) {
        activeIndex = i;
        break;
      }
    }
    final allPast = _items.every((i) => i.timeMin < _nowMin);
    final doneCount = _items.where((i) => i.timeMin < _nowMin).length;

    // Timeline rows with a heading whenever the part of the day changes.
    final rows = <Widget>[
      FadeSlideIn(
        child: _SummaryCard(
          next: allPast ? null : _items[activeIndex],
          nextTime: allPast ? null : _formatTime(_items[activeIndex].timeMin),
          done: doneCount,
          total: _items.length,
          lang: lang,
        ),
      ),
      const SizedBox(height: 8),
    ];
    _DayPart? lastPart;
    for (var index = 0; index < _items.length; index++) {
      final item = _items[index];
      final part = _DayPart.of(item.timeMin);
      if (part != lastPart) {
        rows.add(_PartHeading(part: part, lang: lang));
        lastPart = part;
      }
      final isPast = item.timeMin < _nowMin;
      final isActive = index == activeIndex && !isPast;
      rows.add(
        FadeSlideIn(
          delay: Duration(milliseconds: 60 * index.clamp(0, 8)),
          child: _TimelineItem(
            entry: item,
            part: part,
            isPast: isPast,
            isActive: isActive,
            timeLabel: _formatTime(item.timeMin),
            isLast: index == _items.length - 1 ||
                _DayPart.of(_items[index + 1].timeMin) != part,
            lang: lang,
          ),
        ),
      );
    }

    final gutter = Screen.gutter(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, 18, gutter, 28),
      children: [
        for (final row in rows) MaxWidth(maxWidth: 820, child: row),
      ],
    );
  }

  String _dateString(String lang) {
    return AppStrings.formattedDate(lang, _now);
  }
}

/// Morning, afternoon, evening or night, each with its own colour.
enum _DayPart {
  morning('Morning', Icons.wb_twilight_rounded, AppColors.marigold, AppColors.marigoldDark),
  afternoon('Afternoon', Icons.wb_sunny_rounded, AppColors.terracotta, AppColors.terracottaDark),
  evening('Evening', Icons.nights_stay_rounded, AppColors.orchid, AppColors.orchid),
  night('Night', Icons.bedtime_rounded, AppColors.indigo, AppColors.indigoDark);

  const _DayPart(this.label, this.icon, this.color, this.deep);

  final String label;
  final IconData icon;
  final Color color;

  /// Readable on light backgrounds.
  final Color deep;

  Color get tint => Color.lerp(color, Colors.white, 0.84)!;

  static _DayPart of(int minute) {
    if (minute < 720) return morning;
    if (minute < 1020) return afternoon;
    if (minute < 1200) return evening;
    return night;
  }
}

/// Coloured card at the top: what comes next and how much of the day is done.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.next,
    required this.nextTime,
    required this.done,
    required this.total,
    required this.lang,
  });

  final RoutineItem? next;
  final String? nextTime;
  final int done;
  final int total;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final part = next == null ? _DayPart.night : _DayPart.of(next!.timeMin);
    final onCard = part == _DayPart.morning ? AppColors.primaryText : AppColors.onColor;
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: part.color,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: AppColors.medallion,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: next == null
                    ? Icon(Icons.bedtime_rounded, size: 36, color: part.deep)
                    : RoutinePhoto(id: next!.id, emoji: next!.iconAsset, label: next!.labelKey, size: 68),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      next == null ? AppStrings.thatsAllForToday(lang) : AppStrings.comingUpNext(lang),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: onCard.withValues(alpha: 0.88),
                      ),
                    ),
                    Text(
                      next == null
                          ? AppStrings.routineLabel(lang, 'Time to rest')
                          : AppStrings.routineLabel(lang, next!.labelKey),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: onCard,
                        height: 1.15,
                      ),
                    ),
                    if (nextTime != null)
                      Text(
                        nextTime!,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: onCard,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: onCard.withValues(alpha: 0.22),
              valueColor: AlwaysStoppedAnimation(
                part == _DayPart.morning ? AppColors.leafGreenDark : AppColors.onColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.doneCountSoFar(lang, done, total),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: onCard,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Morning", "Afternoon" and so on, as a coloured chip.
class _PartHeading extends StatelessWidget {
  const _PartHeading({required this.part, required this.lang});

  final _DayPart part;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
            decoration: BoxDecoration(
              color: part.tint,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconMedallion(
                  icon: part.icon,
                  color: part == _DayPart.morning ? AppColors.primaryText : AppColors.onColor,
                  background: part.color,
                  size: 36,
                ),
                const SizedBox(width: 10),
                Text(
                  AppStrings.dayPartLabel(lang, part.name),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: part.deep,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 2, color: part.tint)),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.entry,
    required this.part,
    required this.isPast,
    required this.isActive,
    required this.timeLabel,
    required this.isLast,
    required this.lang,
  });

  final RoutineItem entry;
  final _DayPart part;
  final bool isPast;
  final bool isActive;
  final String timeLabel;
  final bool isLast;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final color = part.color;
    final onActive = part == _DayPart.morning ? AppColors.primaryText : AppColors.onColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 34,
            child: Column(
              children: [
                const SizedBox(height: 30),
                Container(
                  width: isActive ? 24 : 16,
                  height: isActive ? 24 : 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPast ? color.withValues(alpha: 0.35) : color,
                    border: Border.all(color: AppColors.raisedSurface, width: 3),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 4,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12, left: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: isActive ? color : (isPast ? part.tint.withValues(alpha: 0.55) : part.tint),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    // Colour strip on the left
                    Container(
                      width: 8,
                      color: isActive ? Color.lerp(color, Colors.black, 0.18) : color.withValues(alpha: isPast ? 0.35 : 1),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: isActive ? 62 : 54,
                              height: isActive ? 62 : 54,
                              decoration: const BoxDecoration(
                                color: AppColors.raisedSurface,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Opacity(
                                opacity: isPast ? 0.55 : 1,
                                child: RoutinePhoto(id: entry.id, emoji: entry.iconAsset, label: entry.labelKey, size: isActive ? 62 : 54),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.routineLabel(lang, entry.labelKey),
                                    style: TextStyle(
                                      fontSize: isActive ? 24 : 21,
                                      fontWeight: FontWeight.w800,
                                      color: isActive
                                          ? onActive
                                          : isPast
                                              ? AppColors.secondaryText
                                              : AppColors.primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 20,
                                        color: isActive ? onActive : part.deep.withValues(alpha: isPast ? 0.6 : 1),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        timeLabel,
                                        style: TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w700,
                                          color: isActive ? onActive : part.deep.withValues(alpha: isPast ? 0.6 : 1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.raisedSurface,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  AppStrings.nowBadge(lang),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: part.deep,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
