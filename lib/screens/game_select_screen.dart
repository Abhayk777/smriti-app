import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/db/database.dart';
import '../core/progression/progression_service.dart';
import '../core/repo/event_repo.dart';
import '../games/game_catalog.dart';
import '../ui/smriti_ui.dart';
import 'diagnostics_screen.dart';
import 'game_screen.dart';

/// Game selection screen with all 9 cognitive games.
///
/// Each game has its own colour and icon. Phones show one large tile per
/// game with a short description; tablets show a colourful grid.
class GameSelectScreen extends StatelessWidget {
  const GameSelectScreen({super.key, this.service});

  final ProgressionService? service;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 520;
    final gutter = Screen.gutter(context);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Choose a Game',
              subtitle: compact ? null : 'Pick any game you like',
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
            RestAdviceCard(service: service),
            Expanded(
              child: compact
                  ? ListView.separated(
                      padding: EdgeInsets.fromLTRB(gutter, 18, gutter, 28),
                      itemCount: gameCatalog.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) => FadeSlideIn(
                        delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
                        child: _GameTile(
                          info: gameCatalog[index],
                          onTap: () => _launchGame(context, gameCatalog[index]),
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 28),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 380,
                        mainAxisExtent: 220,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                      ),
                      itemCount: gameCatalog.length,
                      itemBuilder: (context, index) => FadeSlideIn(
                        delay: Duration(milliseconds: 40 * index),
                        child: _GameCard(
                          info: gameCatalog[index],
                          onTap: () => _launchGame(context, gameCatalog[index]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchGame(BuildContext context, GameInfo info) {
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
/// A calm, closable daily-rest suggestion. It never controls game launching.
class RestAdviceCard extends StatefulWidget {
  const RestAdviceCard({super.key, this.service});

  final ProgressionService? service;

  @override
  State<RestAdviceCard> createState() => _RestAdviceCardState();
}

class _RestAdviceCardState extends State<RestAdviceCard> {
  RestAdvice? _advice;
  bool _hidden = false;

  ProgressionService get _service => widget.service ?? ProgressionService.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final advice = await _service.restAdvice();
    if (mounted) setState(() => _advice = advice);
  }

  Future<void> _answer(bool keepPlaying) async {
    await _service.onRestCardAnswered(keepPlaying: keepPlaying);
    if (!mounted) return;
    setState(() => _hidden = true);
    if (!keepPlaying) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final advice = _advice;
    if (_hidden || advice == null || !advice.show) return const SizedBox.shrink();
    return FadeSlideIn(
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Color.lerp(AppColors.leafGreen, Colors.white, 0.85), borderRadius: BorderRadius.circular(28)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [IconMedallion(icon: Icons.local_cafe_rounded, color: AppColors.leafGreen, size: 52), const SizedBox(width: 12), const Expanded(child: Text('Time for a little rest', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primaryText)))]),
            const SizedBox(height: 12),
            Text('You have played for ${advice.minutesToday} minutes today. Well done! How about a cup of tea or a short walk?', style: const TextStyle(fontSize: 20, height: 1.3, color: AppColors.primaryText)),
            const SizedBox(height: 14),
            SizedBox(height: 64, child: ElevatedButton(onPressed: () => _answer(false), style: ElevatedButton.styleFrom(backgroundColor: AppColors.leafGreen), child: const Text('Rest now', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)))),
            const SizedBox(height: 10),
            SizedBox(height: 64, child: OutlinedButton(onPressed: () => _answer(true), child: const Text('Keep playing', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)))),
          ],
        ),
      ),
    );
  }
}

/// Phone tile: coloured band with icon, name and a one-line description.
class _GameTile extends StatelessWidget {
  const _GameTile({required this.info, required this.onTap});

  final GameInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: onTap,
      color: info.color,
      radius: 26,
      semanticLabel: info.name,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Row(
        children: [
          IconMedallion(icon: info.icon, color: info.color, size: 72),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onColor,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.description,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onColor.withValues(alpha: 0.9),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.play_circle_fill_rounded,
              color: AppColors.onColor, size: 40),
        ],
      ),
    );
  }
}

/// Tablet card: coloured card with a large icon, name and description.
class _GameCard extends StatelessWidget {
  const _GameCard({required this.info, required this.onTap});

  final GameInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: onTap,
      color: info.color,
      radius: 28,
      semanticLabel: info.name,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconMedallion(icon: info.icon, color: info.color, size: 64),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Color.lerp(info.color, Colors.black, 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  info.domain,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onColor,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            info.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: AppColors.onColor,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            info.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.onColor.withValues(alpha: 0.9),
            ),
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
    final info = gameInfoFor(first);
    if (info != null) return info.name;
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
