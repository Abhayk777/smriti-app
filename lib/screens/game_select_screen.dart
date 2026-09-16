import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/db/database.dart';
import '../core/repo/event_repo.dart';
import 'diagnostics_screen.dart';
import 'game_screen.dart';
import '../ui/smriti_ui.dart';

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
  });

  final String id;
  final String name;
  final String description;
  final String domain;
  final IconData icon;
  final Color color;
  final int tier; // 1 = must ship, 2 = if schedule holds, 3 = if you can
}

/// All 9 games in the roster.
const _games = <_GameInfo>[
  // Tier 1 — must ship
  _GameInfo(
    id: 'faces_of_family',
    name: 'Faces of My Family',
    description: 'Recognise your family members',
    domain: 'Memory',
    icon: Icons.people_alt_rounded,
    color: AppColors.terracotta,
    tier: 1,
  ),
  _GameInfo(
    id: 'market_basket',
    name: 'Market Basket',
    description: 'Remember items from a shopping list',
    domain: 'Memory',
    icon: Icons.shopping_basket_rounded,
    color: AppColors.marigoldDark,
    tier: 1,
  ),
  _GameInfo(
    id: 'sort_harvest',
    name: 'Sort the Harvest',
    description: 'Sort produce by type, colour, or size',
    domain: 'Executive',
    icon: Icons.category_rounded,
    color: AppColors.leafGreen,
    tier: 1,
  ),
  _GameInfo(
    id: 'trace_path',
    name: 'Trace the Path',
    description: 'Connect the stones in order',
    domain: 'Visuospatial',
    icon: Icons.route_rounded,
    color: AppColors.indigo,
    tier: 1,
  ),
  _GameInfo(
    id: 'my_day',
    name: 'My Day',
    description: 'Order daily events and answer questions',
    domain: 'Orientation',
    icon: Icons.wb_sunny_rounded,
    color: AppColors.riverTeal,
    tier: 1,
  ),
  // Tier 2 — build if schedule holds
  _GameInfo(
    id: 'lamps_festival',
    name: 'Lamps of the Festival',
    description: 'Remember the lamp sequence',
    domain: 'Spatial Memory',
    icon: Icons.emoji_objects_rounded,
    color: AppColors.terracottaDark,
    tier: 2,
  ),
  _GameInfo(
    id: 'name_harvest',
    name: 'Name the Harvest',
    description: 'Name as many items as you can',
    domain: 'Language',
    icon: Icons.record_voice_over_rounded,
    color: AppColors.leafGreenDark,
    tier: 2,
  ),
  // Tier 3 — ship if you can
  _GameInfo(
    id: 'weaving_patterns',
    name: 'Weaving Patterns',
    description: 'Match the textile pattern',
    domain: 'Visual Perception',
    icon: Icons.texture_rounded,
    color: AppColors.gamosaRed,
    tier: 3,
  ),
  _GameInfo(
    id: 'sounds_home',
    name: 'Sounds of Home',
    description: 'Tap the drum when you hear the bird',
    domain: 'Attention',
    icon: Icons.hearing_rounded,
    color: AppColors.indigoDark,
    tier: 3,
  ),
];

/// Game selection screen with all 9 cognitive games.
///
/// Calm cards with a clear icon, the game name and what it exercises.
/// The grid adapts: two columns on phones, three or four on tablets.
class GameSelectScreen extends StatelessWidget {
  const GameSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    final gutter = Screen.gutter(context);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Choose a Game',
              icon: Icons.extension_rounded,
              color: AppColors.terracotta,
              actions: [
                IconButton(
                  tooltip: 'Sync & Diagnostics',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
                    );
                  },
                  iconSize: 28,
                  icon: const Icon(Icons.sync_rounded, color: AppColors.secondaryText),
                ),
                const SizedBox(width: 4),
                compact
                    ? IconButton(
                        tooltip: 'Play History',
                        onPressed: () => _showHistoryDialog(context),
                        iconSize: 28,
                        icon: const Icon(Icons.bar_chart_rounded,
                            color: AppColors.terracottaDark),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => _showHistoryDialog(context),
                        icon: const Icon(Icons.bar_chart_rounded, size: 24),
                        label: const Text('Play History'),
                      ),
              ],
            ),

            // Game grid
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 24),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: compact ? 240 : 300,
                  mainAxisExtent: compact ? 196 : 196,
                  crossAxisSpacing: compact ? 12 : 18,
                  mainAxisSpacing: compact ? 12 : 18,
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

class _GameCard extends StatelessWidget {
  const _GameCard({required this.info, required this.onTap});

  final _GameInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: onTap,
      borderColor: AppColors.border,
      semanticLabel: info.name,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconMedallion(
            icon: info.icon,
            color: info.color,
            size: 64,
            background: info.color.withValues(alpha: 0.12),
          ),
          const Spacer(),
          Text(
            info.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: info.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info.domain,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ],
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
      if (g.id == first) return g.name;
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

    final screen = MediaQuery.sizeOf(context);
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Row(
        children: [
          const Icon(Icons.bar_chart_rounded, color: AppColors.terracotta, size: 28),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Play History',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: AppColors.primaryText,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: screen.width < 640 ? screen.width - 32 : 600,
        height: isCompact ? 240 : (screen.height * 0.6).clamp(240.0, 480.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
            : _sessions.isEmpty
                ? const Center(
                    child: Text(
                      'No games played yet.\nPlay a game to see your activity here.',
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
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
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
