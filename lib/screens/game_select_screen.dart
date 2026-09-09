import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/db/database.dart';
import '../core/repo/event_repo.dart';
import 'diagnostics_screen.dart';
import 'game_screen.dart';

/// Game data for display.
class _GameInfo {
  const _GameInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.domain,
    required this.icon,
    required this.color,
    required this.tier,
    required this.emoji,
  });

  final String id;
  final String name;
  final String description;
  final String domain;
  final IconData icon;
  final Color color;
  final int tier; // 1 = must ship, 2 = if schedule holds, 3 = if you can
  final String emoji;
}

/// All 9 games in the roster.
const _games = <_GameInfo>[
  // Tier 1 — must ship
  _GameInfo(
    id: 'faces_of_family',
    name: 'Faces of My Family',
    description: 'Recognise your family members',
    domain: 'Memory',
    icon: Icons.family_restroom,
    color: AppColors.terracotta,
    tier: 1,
    emoji: '👨‍👩‍👧‍👦',
  ),
  _GameInfo(
    id: 'market_basket',
    name: 'Market Basket',
    description: 'Remember items from a shopping list',
    domain: 'Memory',
    icon: Icons.shopping_basket,
    color: AppColors.marigold,
    tier: 1,
    emoji: '🧺',
  ),
  _GameInfo(
    id: 'sort_harvest',
    name: 'Sort the Harvest',
    description: 'Sort produce by type, colour, or size',
    domain: 'Executive',
    icon: Icons.agriculture,
    color: AppColors.leafGreen,
    tier: 1,
    emoji: '🌾',
  ),
  _GameInfo(
    id: 'trace_path',
    name: 'Trace the Path',
    description: 'Connect the stones in order',
    domain: 'Visuospatial',
    icon: Icons.route,
    color: AppColors.indigo,
    tier: 1,
    emoji: '🗺️',
  ),
  _GameInfo(
    id: 'my_day',
    name: 'My Day',
    description: 'Order daily events and answer questions',
    domain: 'Orientation',
    icon: Icons.wb_sunny,
    color: AppColors.marigoldDark,
    tier: 1,
    emoji: '☀️',
  ),
  // Tier 2 — build if schedule holds
  _GameInfo(
    id: 'lamps_festival',
    name: 'Lamps of the Festival',
    description: 'Remember the lamp sequence',
    domain: 'Spatial Memory',
    icon: Icons.local_fire_department,
    color: Color(0xFFE67E22),
    tier: 2,
    emoji: '🪔',
  ),
  _GameInfo(
    id: 'name_harvest',
    name: 'Name the Harvest',
    description: 'Name as many items as you can',
    domain: 'Language',
    icon: Icons.record_voice_over,
    color: AppColors.leafGreenDark,
    tier: 2,
    emoji: '🗣️',
  ),
  // Tier 3 — ship if you can
  _GameInfo(
    id: 'weaving_patterns',
    name: 'Weaving Patterns',
    description: 'Match the textile pattern',
    domain: 'Visual Perception',
    icon: Icons.grid_on,
    color: AppColors.terracottaDark,
    tier: 3,
    emoji: '🧶',
  ),
  _GameInfo(
    id: 'sounds_home',
    name: 'Sounds of Home',
    description: 'Tap the drum when you hear the bird',
    domain: 'Attention',
    icon: Icons.hearing,
    color: Color(0xFF2C5F2D),
    tier: 3,
    emoji: '🐦',
  ),
];

/// Game selection screen with all 9 cognitive games.
///
/// Shows tier-grouped game cards with cultural icons and domain labels.
/// Large touch targets for elderly users.
class GameSelectScreen extends StatelessWidget {
  const GameSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.height < 500;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(24, isCompact ? 10 : 20, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        size: 28, color: AppColors.primaryText),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Choose a Game',
                    style: TextStyle(
                      fontSize: isCompact ? 22 : 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Sync & Diagnostics',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
                      );
                    },
                    icon: const Icon(Icons.sync_rounded, color: AppColors.terracotta, size: 26),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () => _showHistoryDialog(context),
                    icon: const Icon(Icons.bar_chart_rounded,
                        color: AppColors.terracotta),
                    label: Text(
                      'Play History',
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.terracotta,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isCompact ? 10 : 20),

            // Game grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isCompact ? 4 : 3,
                    crossAxisSpacing: isCompact ? 12 : 16,
                    mainAxisSpacing: isCompact ? 12 : 16,
                    childAspectRatio: isCompact ? 1.3 : 1.1,
                  ),
                  itemCount: _games.length,
                  itemBuilder: (context, index) {
                    return _GameCard(
                      info: _games[index],
                      onTap: () => _launchGame(context, _games[index]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchGame(BuildContext context, _GameInfo info) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(gameId: info.id),
      ),
    );
  }

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _PlayHistoryDialog(),
    );
  }
}

class _GameCard extends StatefulWidget {
  const _GameCard({required this.info, required this.onTap});

  final _GameInfo info;
  final VoidCallback onTap;

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final isCompact = MediaQuery.of(context).size.height < 500;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                info.color,
                info.color.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: info.color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 8 : 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Emoji
                Text(
                  info.emoji,
                  style: TextStyle(fontSize: isCompact ? 28 : 40),
                ),
                SizedBox(height: isCompact ? 4 : 10),

                // Game name
                Text(
                  info.name,
                  style: TextStyle(
                    fontSize: isCompact ? 13 : 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isCompact ? 2 : 4),

                // Domain tag
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 6 : 10,
                    vertical: isCompact ? 2 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    info.domain,
                    style: TextStyle(
                      fontSize: isCompact ? 9 : 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog showing what games were played and for how long.
class _PlayHistoryDialog extends StatefulWidget {
  const _PlayHistoryDialog();

  @override
  State<_PlayHistoryDialog> createState() => _PlayHistoryDialogState();
}

class _PlayHistoryDialogState extends State<_PlayHistoryDialog> {
  late final EventRepo _eventRepo = EventRepo(appDatabase);
  List<Session> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await _eventRepo.getRecentSessions(limit: 50);
    if (mounted) {
      setState(() {
        _sessions = list;
        _loading = false;
      });
    }
  }

  String _formatDuration(int? startedAt, int? endedAt, int? abandonedAtMs) {
    if (abandonedAtMs != null && abandonedAtMs > 0) {
      final sec = abandonedAtMs ~/ 1000;
      final m = sec ~/ 60;
      final s = sec % 60;
      return '${m}m ${s}s';
    }
    if (startedAt != null && endedAt != null && endedAt > startedAt) {
      final sec = (endedAt - startedAt) ~/ 1000;
      final m = sec ~/ 60;
      final s = sec % 60;
      return '${m}m ${s}s';
    }
    return '< 1m';
  }

  String _formatDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final timeStr = '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    if (isToday) return 'Today at $timeStr';
    return '${dt.day}/${dt.month}/${dt.year} at $timeStr';
  }

  String _gameDisplayName(String gameIds) {
    final first = gameIds.split(',').first.trim();
    for (final g in _games) {
      if (g.id == first) return '${g.emoji} ${g.name}';
    }
    return first.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.height < 500;

    int totalPlaySeconds = 0;
    for (final s in _sessions) {
      if (s.abandonedAtMs != null) {
        totalPlaySeconds += s.abandonedAtMs! ~/ 1000;
      } else if (s.endedAt != null && s.endedAt! > s.startedAt) {
        totalPlaySeconds += (s.endedAt! - s.startedAt) ~/ 1000;
      }
    }
    final totalMins = totalPlaySeconds ~/ 60;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.history_edu_rounded, color: AppColors.terracotta, size: 28),
          const SizedBox(width: 10),
          const Text(
            'Play Activity History',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: AppColors.primaryText,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: isCompact ? 240 : 380,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
            : _sessions.isEmpty
                ? const Center(
                    child: Text(
                      'No games played yet.\nPlay a game to see your activity here!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: AppColors.secondaryText),
                    ),
                  )
                : Column(
                    children: [
                      // Overview summary row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.pageBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${_sessions.length}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.terracotta,
                                  ),
                                ),
                                const Text(
                                  'Sessions Played',
                                  style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 28, color: AppColors.border),
                            Column(
                              children: [
                                Text(
                                  '${totalMins}m',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.leafGreen,
                                  ),
                                ),
                                const Text(
                                  'Total Play Time',
                                  style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Session list
                      Expanded(
                        child: ListView.separated(
                          itemCount: _sessions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final s = _sessions[i];
                            final duration = _formatDuration(s.startedAt, s.endedAt, s.abandonedAtMs);
                            final date = _formatDate(s.startedAt);

                            return ListTile(
                              dense: isCompact,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              title: Text(
                                _gameDisplayName(s.gameIds),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              subtitle: Text(
                                date,
                                style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    duration,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                  Text(
                                    s.completed ? 'Completed' : 'Stopped early',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: s.completed ? AppColors.leafGreen : AppColors.secondaryText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
