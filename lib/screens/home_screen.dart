import 'dart:async';

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/sync/sync_engine.dart';
import 'diagnostics_screen.dart';
import 'family_screen.dart';
import 'game_select_screen.dart';
import 'medicine_screen.dart';
import 'music_screen.dart';
import 'my_day_screen.dart';
import 'photos_screen.dart';
import 'voice_memo_screen.dart';

/// Main home screen for the elder.
///
/// Large, warm, culturally-informed design. Shows:
/// - Greeting with time of day
/// - Large clock
/// - Game button (primary action)
/// - Medication reminders (when due)
/// - Quick actions (voice memo, people album)
///
/// Hidden diagnostics access: long-press bottom-left corner (AGENTS.md #9).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  String _elderName = '';
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  int _diagnosticsTapCount = 0;
  Timer? _diagnosticsTapResetTimer;

  late AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadElderName();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Trigger initial sync and heartbeat
    unawaited(SyncEngine.defaultInstance.run(trigger: SyncTrigger.appForeground));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(SyncEngine.defaultInstance.run(trigger: SyncTrigger.appForeground));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _diagnosticsTapResetTimer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  Future<void> _loadElderName() async {
    final name =
        await appDatabase.appConfigsDao.getValue('elderName') ?? '';
    if (mounted) setState(() => _elderName = name);
  }

  String _greeting() {
    final hour = _now.hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _timeString() {
    final hour = _now.hour;
    final minute = _now.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Background decorative elements
            _buildDecorations(),

            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Top: greeting and clock
                  _buildGreetingSection(),
                  const SizedBox(height: 24),

                  // Center: main actions
                  _buildMainActions(),
                  const SizedBox(height: 24),

                  // Bottom: quick actions
                  _buildQuickActions(),
                ],
              ),
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

  Widget _buildDecorations() {
    return Stack(
      children: [
        // Top-right decorative circle
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.marigold.withValues(alpha: 0.08),
            ),
          ),
        ),
        // Bottom-left decorative circle
        Positioned(
          bottom: -60,
          left: -60,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.terracotta.withValues(alpha: 0.06),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingSection() {
    final isCompact = MediaQuery.of(context).size.height < 500;
    return Column(
      children: [
        // Greeting - also supports 5-tap to open diagnostics
        GestureDetector(
          onTap: _onDiagnosticsTap,
          behavior: HitTestBehavior.opaque,
          child: Text(
            '${_greeting()}${_elderName.isNotEmpty ? ', $_elderName' : ''}',
            style: TextStyle(
              fontSize: isCompact ? 22 : 30,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Date
        Text(
          _dateString(),
          style: TextStyle(
            fontSize: isCompact ? 14 : 18,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryText,
          ),
        ),
        SizedBox(height: isCompact ? 10 : 20),

        // Large clock
        AnimatedBuilder(
          animation: _breathController,
          builder: (context, child) {
            final glow = 0.1 + _breathController.value * 0.1;
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 24 : 36,
                vertical: isCompact ? 8 : 20,
              ),
              decoration: BoxDecoration(
                color: AppColors.raisedSurface,
                borderRadius: BorderRadius.circular(isCompact ? 16 : 24),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.marigold.withValues(alpha: glow),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                _timeString(),
                style: TextStyle(
                  fontSize: isCompact ? 36 : 56,
                  fontWeight: FontWeight.w300,
                  color: AppColors.primaryText,
                  letterSpacing: isCompact ? 2 : 4,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMainActions() {
    final isCompact = MediaQuery.of(context).size.height < 500;
    final spacing = isCompact ? 14.0 : 24.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Play Games button - large and primary
        _buildLargeButton(
          emoji: '🎮',
          label: 'Play Games',
          sublabel: 'Exercise your mind',
          color: AppColors.terracotta,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const GameSelectScreen(),
              ),
            );
          },
        ),
        SizedBox(width: spacing),

        // My Family button
        _buildLargeButton(
          emoji: '👨‍👩‍👧‍👦',
          label: 'My Family',
          sublabel: 'See your loved ones',
          color: AppColors.indigo,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FamilyScreen()),
            );
          },
        ),
        SizedBox(width: spacing),

        // My Day button
        _buildLargeButton(
          emoji: '📅',
          label: 'My Day',
          sublabel: 'Today\'s schedule',
          color: AppColors.marigold,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyDayScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLargeButton({
    required String emoji,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isCompact = MediaQuery.of(context).size.height < 500;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isCompact ? 140 : 180,
        height: isCompact ? 130 : 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.85)],
          ),
          borderRadius: BorderRadius.circular(isCompact ? 20 : 28),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: isCompact ? 10 : 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: TextStyle(fontSize: isCompact ? 32 : 50)),
            SizedBox(height: isCompact ? 6 : 12),
            Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 15 : 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: isCompact ? 11 : 13,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bottomStrip,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickAction(
            icon: Icons.mic,
            label: 'Voice Memo',
            color: AppColors.terracotta,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VoiceMemoScreen()),
              );
            },
          ),
          _buildQuickAction(
            icon: Icons.medical_services,
            label: 'Medicine',
            color: AppColors.leafGreen,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MedicineScreen()),
              );
            },
          ),
          _buildQuickAction(
            icon: Icons.photo_album,
            label: 'Photos',
            color: AppColors.indigo,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PhotosScreen()),
              );
            },
          ),
          _buildQuickAction(
            icon: Icons.music_note,
            label: 'Music',
            color: AppColors.marigold,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MusicScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
