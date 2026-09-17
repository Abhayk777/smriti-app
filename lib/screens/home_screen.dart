import 'dart:async';

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/progression/progression_service.dart';
import '../core/sync/sync_engine.dart';
import '../ui/day_scene.dart';
import '../ui/smriti_ui.dart';
import 'diagnostics_screen.dart';
import 'family_screen.dart';
import 'game_select_screen.dart';
import 'medicine_screen.dart';
import 'my_day_screen.dart';
import 'voice_memo_screen.dart';

/// Main home screen for the elder.
///
/// A greeting card with the time, date and a small hill landscape, then one
/// large tile each for games, family and today's routine. Message and
/// Medicine sit in a footer that is always in reach. Phones scroll one
/// column; wide tablets put the greeting beside the tiles.
///
/// Hidden diagnostics access: tap the greeting five times, or the bottom-left
/// corner of the page five times (AGENTS.md #9).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String _elderName = '';
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  int _diagnosticsTapCount = 0;
  Timer? _diagnosticsTapResetTimer;
  Timer? _periodicSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadElderName();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    // Trigger initial sync and heartbeat
    unawaited(SyncEngine.defaultInstance.run(trigger: SyncTrigger.appForeground));

    // Catch up any game whose 4-day review is due (docs/PROGRESSION_PLAN.md §6.1).
    unawaited(ProgressionService.instance.runDueReviews());

    // Periodic automatic background sync while app is active
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      unawaited(SyncEngine.defaultInstance.run(trigger: SyncTrigger.periodic));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) setState(() => _now = DateTime.now());
      unawaited(SyncEngine.defaultInstance.run(trigger: SyncTrigger.appForeground));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _diagnosticsTapResetTimer?.cancel();
    _periodicSyncTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadElderName() async {
    final name =
        await appDatabase.appConfigsDao.getValue('elderName') ?? '';
    if (mounted) setState(() => _elderName = name);
  }

  String _greeting() {
    final hour = _now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  IconData _greetingIcon() {
    final hour = _now.hour;
    if (hour < 17) return Icons.wb_sunny_rounded;
    if (hour < 20) return Icons.wb_twilight_rounded;
    return Icons.nightlight_round;
  }

  String _timeString() => formatClock(_now.hour, _now.minute);

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

  void _onDiagnosticsTap() {
    _diagnosticsTapCount++;
    _diagnosticsTapResetTimer?.cancel();
    _diagnosticsTapResetTimer = Timer(const Duration(seconds: 3), () {
      _diagnosticsTapCount = 0;
    });

    if (_diagnosticsTapCount >= 5) {
      _diagnosticsTapCount = 0;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
      );
    }
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      bottomNavigationBar: _buildFooter(),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720 &&
                    constraints.maxWidth > constraints.maxHeight;
                return wide
                    ? _buildWideLayout(constraints)
                    : _buildPortraitLayout(constraints);
              },
            ),

            // Hidden diagnostics tap area (bottom-left corner)
            Positioned(
              left: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: _onDiagnosticsTap,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Layouts ────────────────────────────────────────────────────────────────

  // Phones, and tablets held upright.
  Widget _buildPortraitLayout(BoxConstraints constraints) {
    final gutter = constraints.maxWidth >= 600 ? 32.0 : 18.0;
    final tileHeight = constraints.maxWidth >= 600 ? 140.0 : 120.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 28),
      child: MaxWidth(
        maxWidth: 760,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeSlideIn(child: _buildGreetingCard()),
            const SizedBox(height: 28),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: _sectionTitle('What would you like to do?'),
            ),
            const SizedBox(height: 14),
            ..._buildTiles(tileHeight, gap: 16),
          ],
        ),
      ),
    );
  }

  // Tablets in landscape.
  Widget _buildWideLayout(BoxConstraints constraints) {
    final tileHeight =
        ((constraints.maxHeight - 48 - 40 - 32) / 3).clamp(110.0, 170.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 12, 24),
            child: FadeSlideIn(child: _buildGreetingCard(tall: true)),
          ),
        ),
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 24, 32, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle('What would you like to do?'),
                const SizedBox(height: 14),
                ..._buildTiles(tileHeight, gap: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }

  List<Widget> _buildTiles(double height, {required double gap}) {
    final tiles = [
      ActionTile(
        title: 'Play',
        subtitle: 'Games for the mind',
        icon: Icons.extension_rounded,
        color: AppColors.terracotta,
        height: height,
        onTap: () => _open(const GameSelectScreen()),
      ),
      ActionTile(
        title: 'My Family',
        subtitle: 'Your loved ones',
        icon: Icons.people_alt_rounded,
        color: AppColors.indigo,
        height: height,
        onTap: () => _open(const FamilyScreen()),
      ),
      ActionTile(
        title: 'My Day',
        subtitle: 'Your day at a glance',
        icon: Icons.wb_sunny_rounded,
        color: AppColors.marigold,
        foreground: AppColors.primaryText,
        iconColor: AppColors.marigoldDark,
        height: height,
        onTap: () => _open(const MyDayScreen()),
      ),
    ];
    return [
      for (var i = 0; i < tiles.length; i++) ...[
        if (i > 0) SizedBox(height: gap),
        FadeSlideIn(
          delay: Duration(milliseconds: 140 + i * 90),
          child: tiles[i],
        ),
      ],
    ];
  }

  // ── Greeting card ──────────────────────────────────────────────────────────

  /// Greeting, time and date stacked above a hill landscape. Everything is in
  /// a column, so long names and large system fonts never run into the hills.
  Widget _buildGreetingCard({bool tall = false}) {
    final nameSize = tall ? 52.0 : 40.0;
    final lightText = DayScene.prefersLightText(_now);
    final ink = lightText ? AppColors.onColor : AppColors.primaryText;
    final shadow = [
      Shadow(
        color: (lightText ? Colors.black : Colors.white).withValues(alpha: 0.35),
        blurRadius: 8,
      ),
    ];

    final text = Padding(
      padding: EdgeInsets.fromLTRB(tall ? 32 : 22, tall ? 30 : 22, tall ? 32 : 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            // Also supports 5-tap to open diagnostics
            onTap: _onDiagnosticsTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      _greetingIcon(),
                      color: lightText ? const Color(0xFFF3E6B8) : AppColors.marigoldDark,
                      size: nameSize * 0.6,
                      shadows: shadow,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _elderName.isNotEmpty ? '${_greeting()},' : _greeting(),
                        style: TextStyle(
                          fontSize: nameSize * 0.58,
                          fontWeight: FontWeight.w600,
                          color: ink,
                          height: 1.2,
                          shadows: shadow,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_elderName.isNotEmpty)
                  Text(
                    _elderName,
                    style: TextStyle(
                      fontSize: nameSize,
                      fontWeight: FontWeight.w800,
                      color: ink,
                      height: 1.15,
                      shadows: shadow,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: tall ? 24 : 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _infoChip(
                icon: Icons.schedule_rounded,
                label: _timeString(),
                color: AppColors.terracottaDark,
                big: tall,
              ),
              _infoChip(
                icon: Icons.calendar_today_rounded,
                label: _dateString(),
                color: AppColors.indigo,
                big: tall,
              ),
            ],
          ),
        ],
      ),
    );

    // The landscape follows the real time of day; text sits in the sky above
    // the hills, and the card grows with the text so they never overlap.
    final landHeight = tall ? 230.0 : 130.0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF9CC5EC),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DayScene(now: _now, landHeight: landHeight),
          ),
          tall
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: SingleChildScrollView(child: text)),
                    SizedBox(height: landHeight * 0.75),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    text,
                    SizedBox(height: landHeight * 0.8),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
    bool big = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: big ? 10 : 8),
      decoration: BoxDecoration(
        color: AppColors.raisedSurface,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: big ? 26 : 22),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: big ? 22 : 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.raisedSurface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      child: MaxWidth(
        maxWidth: 900,
        child: Row(
          children: [
            Expanded(
              child: _FooterButton(
                label: 'Message',
                icon: Icons.mic_rounded,
                color: AppColors.riverTeal,
                onTap: () => _open(const VoiceMemoScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FooterButton(
                label: 'Medicine',
                icon: Icons.medication_rounded,
                color: AppColors.leafGreen,
                onTap: () => _open(const MedicineScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: onTap,
      color: color,
      radius: 24,
      semanticLabel: label,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      // Scales down as a whole on narrow phones with large system text, so
      // the label is never cut off.
      child: SizedBox(
        height: 56,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconMedallion(icon: icon, color: color, size: 52),
              const SizedBox(width: 10),
              Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
