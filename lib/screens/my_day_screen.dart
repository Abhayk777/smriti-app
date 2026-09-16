import 'dart:async';

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/db/database.dart';
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
  const MyDayScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _nowMin = _now.hour * 60 + _now.minute;
    _routineSub = _repo.watchRoutineItems().listen((items) {
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    });
    // Pull the latest routine in the background; the subscription above
    // redraws the timeline whenever a sync (this one or any other) lands.
    unawaited(SyncEngine.defaultInstance.run(trigger: SyncTrigger.manual));
  }

  @override
  void dispose() {
    _routineSub?.cancel();
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
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'My Day',
              subtitle: _dateString(),
              icon: Icons.wb_sunny_rounded,
              color: AppColors.marigoldDark,
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.marigold),
                    )
                  : _items.isEmpty
                      ? _buildEmpty()
                      : _buildTimeline(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const EmptyState(
      icon: Icons.event_note_rounded,
      color: AppColors.marigoldDark,
      title: 'Your routine will be updated soon',
      message: 'Your family will add your daily plan here.',
    );
  }

  Widget _buildTimeline() {
    // Find the "active" index: first item whose time >= now, or last
    int activeIndex = _items.length - 1;
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].timeMin >= _nowMin) {
        activeIndex = i;
        break;
      }
    }

    final gutter = Screen.gutter(context);
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 24),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final isPast = item.timeMin < _nowMin;
        final isActive = index == activeIndex && !isPast;

        return MaxWidth(
          maxWidth: 820,
          child: _TimelineItem(
            entry: item,
            isPast: isPast,
            isActive: isActive,
            timeLabel: _formatTime(item.timeMin),
            isLast: index == _items.length - 1,
          ),
        );
      },
    );
  }

  String _dateString() {
    const days = [
      '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${days[_now.weekday]}, ${_now.day} ${months[_now.month]}';
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.entry,
    required this.isPast,
    required this.isActive,
    required this.timeLabel,
    required this.isLast,
  });

  final RoutineItem entry;
  final bool isPast;
  final bool isActive;
  final String timeLabel;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final dotColor = isActive
        ? AppColors.marigold
        : isPast
            ? AppColors.border
            : AppColors.secondaryText.withValues(alpha: 0.45);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 36,
            child: Column(
              children: [
                const SizedBox(height: 26),
                Container(
                  width: isActive ? 22 : 16,
                  height: isActive ? 22 : 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: isActive
                        ? Border.all(color: AppColors.marigoldDark, width: 3)
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.only(top: 4),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),

          // Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12, left: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.marigold.withValues(alpha: 0.16)
                      : isPast
                          ? AppColors.bottomStrip.withValues(alpha: 0.6)
                          : AppColors.raisedSurface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isActive ? AppColors.marigold : AppColors.border,
                    width: isActive ? 2.5 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: isActive ? 60 : 52,
                      height: isActive ? 60 : 52,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.raisedSurface
                            : AppColors.medallion,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: isPast ? 0.6 : 1,
                        child: Text(
                          entry.iconAsset,
                          style: TextStyle(fontSize: isActive ? 30 : 26),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.labelKey,
                            style: TextStyle(
                              fontSize: isActive ? 23 : 20,
                              fontWeight: isActive
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isPast
                                  ? AppColors.secondaryText
                                  : AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 17,
                              color: isActive
                                  ? AppColors.marigoldDark
                                  : AppColors.secondaryText,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.marigoldDark,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onColor,
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
