import 'dart:async';

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/db/database.dart';
import '../core/i18n/app_strings.dart';
import '../core/i18n/locale_controller.dart';
import '../core/progression/progression_service.dart';
import '../core/repo/event_repo.dart';
import '../games/game_catalog.dart';
import '../ui/smriti_ui.dart';
import '../widgets/language_switcher_button.dart';
import 'diagnostics_screen.dart';
import 'game_tutorial_screen.dart';

/// Game selection screen with all 9 cognitive games.
///
/// Each game has its own colour and icon. Phones show one large tile per
/// game with a short description; tablets show a colourful grid.
class GameSelectScreen extends StatefulWidget {
  const GameSelectScreen({super.key, this.service});

  final ProgressionService? service;

  @override
  State<GameSelectScreen> createState() => _GameSelectScreenState();
}

class _GameSelectScreenState extends State<GameSelectScreen> {
  ProgressionService get _service =>
      widget.service ?? ProgressionService.instance;

  final GlobalKey<RestAdviceCardState> _restAdviceKey = GlobalKey<RestAdviceCardState>();
  VarietySuggestion? _suggestion;
  bool _isLocked = false;
  Duration? _lockRemaining;

  @override
  void initState() {
    super.initState();
    _loadSuggestion();
  }

  Future<void> _loadSuggestion() async {
    final advice = await _service.restAdvice();
    if (!mounted) return;
    setState(() {
      _isLocked = advice.isLocked;
      _lockRemaining = advice.lockRemaining;
    });

    if (!_isLocked) {
      final s = await _service.suggestionFor();
      if (!mounted) return;
      setState(() => _suggestion = s);
      if (s != null) {
        unawaited(_service.onNudgeShown(s));
      }
    } else {
      setState(() => _suggestion = null);
    }
  }

  void _onTrySuggested(GameInfo info) {
    unawaited(_service.onNudgeAccepted(info.id));
    _launchGame(info);
  }

  void _onMaybeLater() {
    unawaited(_service.onNudgeDismissed());
    setState(() => _suggestion = null);
  }

  Widget _buildRestingBanner(BuildContext context, bool compact, String lang) {
    final remainingMinutes = _lockRemaining != null
        ? (_lockRemaining!.inMinutes + 1)
        : 180;
    final gutter = Screen.gutter(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Color.lerp(AppColors.leafGreen, Colors.white, 0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            IconMedallion(
              icon: Icons.local_cafe_rounded,
              image: 'rest.jpg',
              color: AppColors.leafGreen,
              size: compact ? 42 : 50,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                AppStrings.restingBannerText(lang, remainingMinutes),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 520;
    final gutter = Screen.gutter(context);
    final suggestion = _suggestion;

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
                  title: AppStrings.games(lang),
                  subtitle: compact ? null : AppStrings.gamesForMind(lang),
                  icon: Icons.extension_rounded,
                  image: 'tile_games.jpg',
                  color: AppColors.terracotta,
                  actions: [
                    LanguageSwitcherButton(compact: compact),
                    const SizedBox(width: 4),
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
                            tooltip: AppStrings.playHistory(lang),
                            onPressed: () => _showHistoryDialog(context),
                            iconSize: 28,
                            icon: const Icon(Icons.bar_chart_rounded,
                                color: AppColors.terracottaDark),
                          )
                        : OutlinedButton.icon(
                            onPressed: () => _showHistoryDialog(context),
                            icon: const Icon(Icons.bar_chart_rounded, size: 24),
                            label: Text(AppStrings.playHistory(lang)),
                          ),
                  ],
                ),
                if (_isLocked)
                  _buildRestingBanner(context, compact, lang)
                else ...[
                  RestAdviceCard(key: _restAdviceKey, service: widget.service, lang: lang),
                  if (suggestion != null)
                    VarietySuggestionCard(
                      suggestion: suggestion,
                      lang: lang,
                      onTrySuggested: () {
                        final info = gameInfoFor(suggestion.suggestedGameId);
                        if (info != null) _onTrySuggested(info);
                      },
                      onMaybeLater: _onMaybeLater,
                    ),
                ],
                Expanded(
                  child: compact
                      ? ListView.separated(
                          padding: EdgeInsets.fromLTRB(gutter, 18, gutter, 28),
                          itemCount: gameCatalog.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final info = gameCatalog[index];
                            final isSuggested = suggestion?.suggestedGameId == info.id;
                            return FadeSlideIn(
                              delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
                              child: _GameTile(
                                info: info,
                                lang: lang,
                                isSuggested: isSuggested,
                                onTap: () {
                                  if (isSuggested) {
                                    unawaited(_service.onNudgeAccepted(info.id));
                                  }
                                  _launchGame(info);
                                },
                              ),
                            );
                          },
                        )
                      : GridView.builder(
                          padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 28),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 380,
                            mainAxisExtent: 240,
                            crossAxisSpacing: 18,
                            mainAxisSpacing: 18,
                          ),
                          itemCount: gameCatalog.length,
                          itemBuilder: (context, index) {
                            final info = gameCatalog[index];
                            final isSuggested = suggestion?.suggestedGameId == info.id;
                            return FadeSlideIn(
                              delay: Duration(milliseconds: 40 * index),
                              child: _GameCard(
                                info: info,
                                lang: lang,
                                isSuggested: isSuggested,
                                onTap: () {
                                  if (isSuggested) {
                                    unawaited(_service.onNudgeAccepted(info.id));
                                  }
                                  _launchGame(info);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchGame(GameInfo info) async {
    final locked = await _service.isGamesLocked();
    if (!mounted) return;
    if (locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Games are taking a restful break right now.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameTutorialScreen(gameId: info.id),
      ),
    );
    if (mounted) {
      _loadSuggestion();
      _restAdviceKey.currentState?.reload();
    }
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
  const RestAdviceCard({super.key, this.service, this.lang});

  final ProgressionService? service;
  final String? lang;

  @override
  State<RestAdviceCard> createState() => RestAdviceCardState();
}

class RestAdviceCardState extends State<RestAdviceCard> {
  RestAdvice? _advice;
  bool _hidden = false;

  ProgressionService get _service => widget.service ?? ProgressionService.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> reload() async {
    _hidden = false;
    await _load();
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
    final l = widget.lang ?? LocaleController.instance.currentLanguage;
    return FadeSlideIn(
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Color.lerp(AppColors.leafGreen, Colors.white, 0.85), borderRadius: BorderRadius.circular(28)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const IconMedallion(icon: Icons.local_cafe_rounded,
              image: 'rest.jpg', color: AppColors.leafGreen, size: 52),
              const SizedBox(width: 12),
              Expanded(child: Text(AppStrings.timeToRestYourEyes(l), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primaryText))),
            ]),
            const SizedBox(height: 12),
            Text(AppStrings.playedTodayMessage(l, advice.minutesToday), style: const TextStyle(fontSize: 20, height: 1.3, color: AppColors.primaryText)),
            const SizedBox(height: 14),
            SizedBox(height: 64, child: ElevatedButton(onPressed: () => _answer(false), style: ElevatedButton.styleFrom(backgroundColor: AppColors.leafGreen), child: Text(AppStrings.restNow(l), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)))),
            const SizedBox(height: 10),
            SizedBox(height: 64, child: OutlinedButton(onPressed: () => _answer(true), child: Text(AppStrings.keepPlaying(l), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)))),
          ],
        ),
      ),
    );
  }
}

/// Phone tile: coloured band with icon, name and a one-line description.
class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.info,
    required this.onTap,
    this.lang,
    this.isSuggested = false,
  });

  final GameInfo info;
  final VoidCallback onTap;
  final String? lang;
  final bool isSuggested;

  @override
  Widget build(BuildContext context) {
    final l = lang ?? LocaleController.instance.currentLanguage;
    final title = AppStrings.gameTitle(l, info.id);
    final desc = AppStrings.gameDescription(l, info.id);

    return PressableCard(
      onTap: onTap,
      color: info.color,
      radius: 26,
      semanticLabel: title,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Row(
        children: [
          IconMedallion(icon: info.icon, image: info.image, color: info.color, size: 72),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSuggested) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.marigold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: AppColors.primaryText),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.tryToday(l),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onColor,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
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
  const _GameCard({
    required this.info,
    required this.onTap,
    this.lang,
    this.isSuggested = false,
  });

  final GameInfo info;
  final VoidCallback onTap;
  final String? lang;
  final bool isSuggested;

  @override
  Widget build(BuildContext context) {
    final l = lang ?? LocaleController.instance.currentLanguage;
    final title = AppStrings.gameTitle(l, info.id);
    final desc = AppStrings.gameDescription(l, info.id);

    return PressableCard(
      onTap: onTap,
      color: info.color,
      radius: 28,
      semanticLabel: title,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconMedallion(icon: info.icon, image: info.image, color: info.color, size: 52),
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
          if (isSuggested) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.marigold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: AppColors.primaryText),
                  const SizedBox(width: 4),
                  Text(
                    AppStrings.tryToday(l),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            title,
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
            desc,
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
                          boxShadow: [BoxShadow(color: AppColors.terracottaDeep.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 3))],
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

/// A gentle suggestion to try a different game when one has become a repeat
/// favourite (docs/PROGRESSION_PLAN.md §8).
class VarietySuggestionCard extends StatelessWidget {
  const VarietySuggestionCard({
    super.key,
    required this.suggestion,
    required this.onTrySuggested,
    required this.onMaybeLater,
    this.lang,
  });

  final VarietySuggestion suggestion;
  final VoidCallback onTrySuggested;
  final VoidCallback onMaybeLater;
  final String? lang;

  @override
  Widget build(BuildContext context) {
    final l = lang ?? LocaleController.instance.currentLanguage;
    final favInfo = gameInfoFor(suggestion.favouriteGameId);
    final favName = favInfo != null
        ? AppStrings.gameTitle(l, favInfo.id)
        : suggestion.favouriteGameId;
    final sugInfo = gameInfoFor(suggestion.suggestedGameId);
    final sugName = sugInfo != null
        ? AppStrings.gameTitle(l, sugInfo.id)
        : suggestion.suggestedGameId;
    final sugColor = sugInfo?.color ?? AppColors.terracotta;

    return FadeSlideIn(
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Color.lerp(AppColors.marigold, Colors.white, 0.8),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const IconMedallion(
                  icon: Icons.lightbulb_rounded,
                  color: AppColors.marigoldDark,
                  size: 52,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppStrings.varietyEnjoy(l, favName),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.varietyTry(l, sugName),
              style: const TextStyle(
                fontSize: 20,
                height: 1.3,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: onTrySuggested,
                style: ElevatedButton.styleFrom(
                  backgroundColor: sugColor,
                ),
                child: Text(
                  AppStrings.tryGame(l, sugName),
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: OutlinedButton(
                onPressed: onMaybeLater,
                child: Text(
                  AppStrings.maybeLater(l),
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

