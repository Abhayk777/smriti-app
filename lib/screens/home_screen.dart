import 'dart:async';

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/sync/sync_engine.dart';
import '../ui/smriti_ui.dart';
import 'diagnostics_screen.dart';
import 'family_screen.dart';
import 'game_select_screen.dart';
import 'medicine_screen.dart';
import 'my_day_screen.dart';
import 'voice_memo_screen.dart';

/// Main home screen for the elder.
///
/// A calm greeting with the time and date, then one large tile per activity:
/// games, family, today's routine, medicines and voice messages. Phones show
/// the tiles as a single column under the greeting; wide tablets place the
/// greeting on the left and the tiles on the right.
///
/// Hidden diagnostics access: tap the greeting five times, or the bottom-left
/// corner five times (AGENTS.md #9).
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

  List<_HomeAction> get _actions => [
        _HomeAction(
          title: 'Play',
          subtitle: 'Games for the mind',
          icon: Icons.extension_rounded,
          color: AppColors.terracotta,
          onTap: () => _open(const GameSelectScreen()),
        ),
        _HomeAction(
          title: 'My Family',
          subtitle: 'Your loved ones',
          icon: Icons.people_alt_rounded,
          color: AppColors.indigo,
          onTap: () => _open(const FamilyScreen()),
        ),
        _HomeAction(
          title: 'My Day',
          subtitle: 'Your day at a glance',
          icon: Icons.wb_sunny_rounded,
          color: AppColors.marigold,
          foreground: AppColors.primaryText,
          iconColor: AppColors.marigoldDark,
          onTap: () => _open(const MyDayScreen()),
        ),
        _HomeAction(
          title: 'Medicine',
          subtitle: 'Today\'s medicines',
          icon: Icons.medication_rounded,
          color: AppColors.leafGreen,
          onTap: () => _open(const MedicineScreen()),
        ),
        _HomeAction(
          title: 'Message',
          subtitle: 'Send a voice note',
          icon: Icons.mic_rounded,
          color: AppColors.riverTeal,
          onTap: () => _open(const VoiceMemoScreen()),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
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

  // Phones, and tablets held upright.
  Widget _buildPortraitLayout(BoxConstraints constraints) {
    final gutter = constraints.maxWidth >= 600 ? 32.0 : 18.0;
    final actions = _actions;
    const gap = 14.0;
    // Fit all tiles on screen when there is room; scroll otherwise.
    final headerHeight = (constraints.maxHeight * 0.21).clamp(170.0, 230.0);
    final available =
        constraints.maxHeight - headerHeight - 16 - gap * (actions.length - 1);
    final tileHeight = (available / actions.length).clamp(88.0, 150.0);

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: headerHeight,
            child: _buildGreetingHeader(gutter: gutter),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 16),
            child: MaxWidth(
              maxWidth: 760,
              child: Column(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(height: gap),
                    _buildTile(actions[i], height: tileHeight),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tablets in landscape.
  Widget _buildWideLayout(BoxConstraints constraints) {
    final actions = _actions;
    const gap = 16.0;
    final tileHeight =
        ((constraints.maxHeight - 48 - gap * (actions.length - 1)) /
                actions.length)
            .clamp(80.0, 160.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: _buildGreetingPanel(),
        ),
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 24, 32, 24),
            child: Column(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(height: gap),
                  _buildTile(actions[i], height: tileHeight),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTile(_HomeAction action, {required double height}) {
    return ActionTile(
      title: action.title,
      subtitle: action.subtitle,
      icon: action.icon,
      color: action.color,
      foreground: action.foreground,
      iconColor: action.iconColor,
      onTap: action.onTap,
      height: height,
    );
  }

  Widget _greetingText({required double nameSize}) {
    return GestureDetector(
      // Also supports 5-tap to open diagnostics
      onTap: _onDiagnosticsTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _elderName.isNotEmpty ? '${_greeting()},' : _greeting(),
            style: TextStyle(
              fontSize: nameSize * 0.62,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
              height: 1.15,
            ),
          ),
          if (_elderName.isNotEmpty)
            Text(
              _elderName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: nameSize,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryText,
                height: 1.1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _timeAndDate({required double timeSize}) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 2,
      children: [
        Text(
          _timeString(),
          style: TextStyle(
            fontSize: timeSize,
            fontWeight: FontWeight.w800,
            color: AppColors.terracottaDark,
          ),
        ),
        Text(
          _dateString(),
          style: TextStyle(
            fontSize: timeSize * 0.78,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingHeader({required double gutter}) {
    return LayoutBuilder(
      builder: (context, c) {
        final nameSize = (c.maxHeight * 0.22).clamp(34.0, 52.0);
        final sceneWidth = (c.maxWidth * 0.34).clamp(120.0, 240.0);
        final sceneHeight = sceneWidth * 0.66;
        return Stack(
          children: [
            // Soft ground curve along the bottom, as in a landscape
            Positioned.fill(
              child: CustomPaint(painter: _GroundPainter()),
            ),
            // Sun over the hills, beside the greeting
            Positioned(
              right: 0,
              top: 8,
              width: sceneWidth,
              height: sceneHeight,
              child: const HillsScene(),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, 18, gutter, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: sceneWidth * 0.7),
                    child: _greetingText(nameSize: nameSize),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.only(bottom: c.maxHeight * 0.16),
                    child: _timeAndDate(timeSize: 21),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGreetingPanel() {
    return LayoutBuilder(
      builder: (context, c) {
        return Container(
          margin: const EdgeInsets.fromLTRB(32, 24, 16, 24),
          decoration: BoxDecoration(
            color: AppColors.raisedSurface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GamosaBand(height: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(36, 20, 36, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _greetingText(nameSize: 52),
                      const SizedBox(height: 24),
                      Text(
                        _timeString(),
                        style: const TextStyle(
                          fontSize: 76,
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracottaDark,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _dateString(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: (c.maxHeight * 0.32).clamp(110.0, 220.0),
                width: double.infinity,
                child: const HillsScene(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeAction {
  const _HomeAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.foreground = AppColors.onColor,
    this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color foreground;
  final Color? iconColor;
  final VoidCallback onTap;
}

/// Gentle sand-coloured ground line under the greeting, as in a landscape.
class _GroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.90)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.80,
        size.width,
        size.height * 0.88,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.bottomStrip);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
