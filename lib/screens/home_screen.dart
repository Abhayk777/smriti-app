import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/repo/ability_repo.dart';
import '../core/repo/content_repo.dart';
import '../core/repo/event_repo.dart';
import '../games/cognitive_game.dart';
import '../games/market_basket/market_basket_game.dart';
import '../games/session_runner.dart';
import 'game_select_screen.dart';

/// The main home screen for the elder.
///
/// This is the primary screen the elder sees after pairing. It provides
/// large, touch-friendly access to:
/// - Games (primary function)
/// - Medication reminders status
/// - Voice memos
/// - Routine display
/// - People directory
///
/// All UI elements are designed for elderly users with:
/// - Large touch targets (minimum 48x48 logical pixels)
/// - High contrast colors
/// - Minimal text, maximum icons/images
/// - Voice-first navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ContentRepo _contentRepo = ContentRepo(appDatabase);
  late final EventRepo _eventRepo = EventRepo(appDatabase);
  late final AbilityRepo _abilityRepo = AbilityRepo(appDatabase);

  String? _elderName;
  int _activeMedications = 0;
  int _nextMedicationMinutes = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Get elder name
    final name = await appDatabase.appConfigsDao.getValue('elderName');
    if (mounted) {
      setState(() => _elderName = name);
    }

    // Count active medications
    final meds = await _contentRepo.getMedications(activeOnly: true);
    if (mounted) {
      setState(() => _activeMedications = meds.length);
    }

    // Find next medication time
    if (meds.isNotEmpty) {
      final now = DateTime.now();
      final nowMinutes = now.hour * 60 + now.minute;
      
      int minNext = 999999;
      for (final med in meds) {
        // Check if this med is due today
        final days = _parseDaysOfWeek(med.daysOfWeek);
        final today = now.weekday; // 1=Monday
        
        if (days.contains(today)) {
          final medMinutes = med.chosenTimeMin;
          if (medMinutes >= nowMinutes) {
            minNext = min(minNext, medMinutes - nowMinutes);
          } else {
            // Wrapped to tomorrow
            minNext = min(minNext, (24 * 60 - nowMinutes) + medMinutes);
          }
        }
      }
      
      if (minNext < 999999 && mounted) {
        setState(() => _nextMedicationMinutes = minNext);
      }
    }
  }

  List<int> _parseDaysOfWeek(String daysOfWeek) {
    return daysOfWeek
        .split(',')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .where((d) => d >= 1 && d <= 7)
        .toList();
  }

  Future<void> _startGameSession() async {
    // Load content
    final content = await _loadGameContent();
    
    // Create game
    final game = MarketBasketGame();
    
    // Create session runner
    final runner = SessionRunner(
      eventRepo: _eventRepo,
      abilityRepo: _abilityRepo,
      content: content,
    );
    
    // Start session
    final sessionId = await runner.start([game]);
    
    // Navigate to game screen
    if (!mounted) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(
          runner: runner,
          game: game,
        ),
      ),
    );
  }

  Future<GameContent> _loadGameContent() async {
    // Try to load from assets
    try {
      final contentJson = await DefaultAssetBundle.of(context)
          .loadString('assets/mock_content/mock_content.json');
      return GameContent.fromJson({
        'version': '1.0',
        'marketItems': [],
      });
    } catch (_) {
      // Return empty content
      return GameContent(version: '1.0', marketItems: const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header with elder name and time
            _buildHeader(),
            
            const SizedBox(height: 30),
            
            // Main action buttons
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Games button (primary action)
                  _buildActionButton(
                    icon: Icons.games,
                    label: 'Play Games',
                    onTap: _startGameSession,
                    color: AppColors.terracotta,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Medications info
                  if (_activeMedications > 0) ...[
                    _buildMedicationInfo(),
                    const SizedBox(height: 20),
                  ],
                  
                  // Secondary actions row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSmallActionButton(
                        icon: Icons.people,
                        label: 'People',
                        onTap: () {},
                      ),
                      const SizedBox(width: 20),
                      _buildSmallActionButton(
                        icon: Icons.mic,
                        label: 'Memo',
                        onTap: () {},
                      ),
                      const SizedBox(width: 20),
                      _buildSmallActionButton(
                        icon: Icons.schedule,
                        label: 'Routine',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Bottom decoration
            const Spacer(),
            _buildBottomDecoration(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final timeStr = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr = '${_dayName(now.weekday)}, ${now.day} ${_monthName(now.month)}';
    
    return Column(
      children: [
        const SizedBox(height: 10),
        
        // Elder name
        if (_elderName != null && _elderName!.isNotEmpty) ...[
          Text(
            'Hello, ${_elderName}!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Time
        Text(
          timeStr,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w300,
            color: AppColors.primaryText,
          ),
        ),
        
        // Date
        Text(
          dateStr,
          style: TextStyle(
            fontSize: 18,
            color: AppColors.secondaryText,
          ),
        ),
        
        const SizedBox(height: 10),
      ],
    );
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        decoration: BoxDecoration(
          color: color ?? AppColors.raisedSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: color != null ? Colors.white : AppColors.terracotta,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: color != null ? Colors.white : AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.raisedSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Icon(
              icon,
              size: 32,
              color: AppColors.terracotta,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationInfo() {
    if (_nextMedicationMinutes < 0) {
      return Text(
        'No medications scheduled today',
        style: TextStyle(
          fontSize: 18,
          color: AppColors.secondaryText,
        ),
      );
    }
    
    final hours = _nextMedicationMinutes! ~/ 60;
    final minutes = _nextMedicationMinutes! % 60;
    
    String timeStr;
    if (hours > 0) {
      timeStr = '$hours hour${hours > 1 ? 's' : ''}';
      if (minutes > 0) {
        timeStr += ' $minutes minute${minutes > 1 ? 's' : ''}';
      }
    } else {
      timeStr = '$minutes minute${minutes > 1 ? 's' : ''}';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.raisedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.medical_services,
            size: 28,
            color: AppColors.terracotta,
          ),
          const SizedBox(width: 12),
          Text(
            'Next medication in $timeStr',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDecoration() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.pageBackground,
            AppColors.wovenMat,
          ],
        ),
      ),
      child: CustomPaint(
        painter: _WavePainter(),
        size: Size.infinite,
      ),
    );
  }
}

/// Game screen for playing cognitive games.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.runner,
    required this.game,
  });

  final SessionRunner runner;
  final CognitiveGame game;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GameItem? _currentItem;
  bool _sessionEnded = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void dispose() {
    if (!_sessionEnded) {
      widget.runner.end(completed: false);
    }
    super.dispose();
  }

  Future<void> _startSession() async {
    // Play intro demo
    await widget.game.playDemo(context);
    
    // Get first item
    _currentItem = await widget.runner.nextItem(widget.game);
    
    if (_currentItem != null) {
      setState(() {});
    }
  }

  Future<void> _nextItem() async {
    _currentItem = await widget.runner.nextItem(widget.game);
    setState(() {});
    
    if (_currentItem == null) {
      // Session ended
      _sessionEnded = true;
      widget.runner.end(completed: true);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        title: Text(widget.game.id.replaceAll('_', ' ').toUpperCase()),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _sessionEnded = true;
              widget.runner.end(completed: false);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: widget.runner.elapsed.inMinutes / 6,
              backgroundColor: AppColors.raisedSurface,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.terracotta),
              minHeight: 6,
            ),
            
            const SizedBox(height: 10),
            
            // Time remaining
            Text(
              'Time remaining: ${6 - widget.runner.elapsed.inMinutes} minutes',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondaryText,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Current item
            if (_currentItem != null) ...[
              Expanded(
                child: Center(
                  child: Text(
                    'Game: ${widget.game.id}',
                    style: TextStyle(
                      fontSize: 20,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ),
              
              // Next button (for demo)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton(
                  onPressed: _nextItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: AppColors.onColor,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Next Item',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Simple wave painter for bottom decoration.
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.leafGreen
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.2,
      size.width * 0.5,
      size.height * 0.6,
    );
    
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.8,
      size.width,
      size.height * 0.4,
    );
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
