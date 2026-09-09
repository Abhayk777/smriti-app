import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/repo/content_repo.dart';
import '../core/sync/sync_engine.dart';

/// Shows the elder's daily routine as a warm timeline.
///
/// Reads `RoutineItems` from local SQLite. Falls back to the bundled
/// mock_content.json if the table is empty (content not yet pulled from server).
/// Highlights the current / next item. Past items are dimmed.
/// No medication items are shown here — those live in MedicineScreen.
class MyDayScreen extends StatefulWidget {
  const MyDayScreen({super.key});

  @override
  State<MyDayScreen> createState() => _MyDayScreenState();
}

class _MyDayScreenState extends State<MyDayScreen> {
  final ContentRepo _repo = ContentRepo(appDatabase);
  List<_RoutineEntry> _items = [];
  bool _loading = true;
  late DateTime _now;
  late int _nowMin; // minutes from midnight

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _nowMin = _now.hour * 60 + _now.minute;
    _load();
    // Auto-refresh routine items from Supabase in the background
    SyncEngine.defaultInstance.run(trigger: SyncTrigger.manual).then((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final dbItems = await _repo.getRoutineItems();
    if (dbItems.isNotEmpty) {
      setState(() {
        _items = dbItems
            .map((r) => _RoutineEntry(
                  id: r.id,
                  timeMin: r.timeMin,
                  label: r.labelKey,
                  icon: r.iconAsset,
                ))
            .toList();
        _loading = false;
      });
    } else {
      // Fall back to mock JSON
      await _loadMock();
    }
  }

  Future<void> _loadMock() async {
    try {
      final raw = await rootBundle.loadString('assets/mock_content/mock_content.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final routine = (data['routineItems'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      setState(() {
        _items = routine
            .map((r) => _RoutineEntry(
                  id: r['id'] as String,
                  timeMin: r['timeMin'] as int,
                  label: r['labelKey'] as String,
                  icon: r['iconAsset'] as String,
                ))
            .toList()
          ..sort((a, b) => a.timeMin.compareTo(b.timeMin));
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
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
            _buildHeader(context),
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

  Widget _buildHeader(BuildContext context) {
    final dateStr = _dateString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.raisedSurface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.marigold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.marigold, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📅  My Day',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📅', style: TextStyle(fontSize: 72)),
          SizedBox(height: 16),
          Text(
            'Your daily schedule will appear here.',
            style: TextStyle(fontSize: 20, color: AppColors.secondaryText),
          ),
        ],
      ),
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final isPast = item.timeMin < _nowMin;
        final isActive = index == activeIndex && !isPast;

        return _TimelineItem(
          entry: item,
          isPast: isPast,
          isActive: isActive,
          timeLabel: _formatTime(item.timeMin),
          isLast: index == _items.length - 1,
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

class _RoutineEntry {
  const _RoutineEntry({
    required this.id,
    required this.timeMin,
    required this.label,
    required this.icon,
  });

  final String id;
  final int timeMin;
  final String label;
  final String icon;
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.entry,
    required this.isPast,
    required this.isActive,
    required this.timeLabel,
    required this.isLast,
  });

  final _RoutineEntry entry;
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
            : AppColors.secondaryText.withValues(alpha: 0.4);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: isActive
                        ? Border.all(color: AppColors.marigoldDark, width: 2)
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),

          // Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.marigold.withValues(alpha: 0.12)
                      : isPast
                          ? AppColors.wovenMat.withValues(alpha: 0.4)
                          : AppColors.raisedSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? AppColors.marigold : AppColors.border,
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      entry.icon,
                      style: TextStyle(fontSize: isActive ? 32 : 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.label,
                            style: TextStyle(
                              fontSize: isActive ? 20 : 17,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isPast
                                  ? AppColors.secondaryText
                                  : AppColors.primaryText,
                            ),
                          ),
                          Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 14,
                              color: isActive
                                  ? AppColors.marigoldDark
                                  : AppColors.secondaryText,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.marigold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Now',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
