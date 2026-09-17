import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app_colors.dart';
import '../core/ability/estimator.dart';
import '../core/db/app_database.dart';
import '../core/db/database.dart';
import '../core/progression/game_level_profiles.dart';
import '../core/progression/level_scale.dart';
import '../core/progression/performance_report.dart';
import '../core/progression/play_policy.dart';
import '../core/progression/progression_config.dart';
import '../core/progression/progression_policy.dart';
import '../core/progression/progression_repo.dart';
import '../core/progression/progression_service.dart';
import '../core/progression/progression_state.dart';
import '../core/reminders/native_reminder_bridge.dart';
import '../core/reminders/reminder_isolate.dart';
import '../core/repo/content_repo.dart';
import '../core/repo/event_repo.dart';
import '../core/sync/sync_engine.dart';
import '../games/game_catalog.dart';
import 'reminder_setup_screen.dart';

/// Diagnostics screen for caregiver use only.
///
/// Hidden behind kiosk exit (long-press corner + PIN). Shows:
/// - Patient/device ID
/// - Content version
/// - Last sync time/error
/// - Pending event count
/// - Auth status
/// - Clock skew
/// - Health check results with re-run
/// - Next scheduled alarms
/// - "Fire test reminder now" button
///
/// Uses normal density UI (not elder styling) as it's caregiver-facing.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key, this.service, this.syncEngine});

  final ProgressionService? service;
  final SyncEngine? syncEngine;

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  late final SmritiDatabase _db = widget.service?.db ?? appDatabase;
  late final ContentRepo _contentRepo = ContentRepo(_db);
  late final EventRepo _eventRepo = EventRepo(_db);
  SyncEngine get _syncEngine => widget.syncEngine ?? SyncEngine.defaultInstance;

  ProgressionService get _progressionService =>
      widget.service ?? ProgressionService.instance;

  String? _patientId;
  String? _deviceUserId;
  String? _contentVersion;
  String? _lastSyncAt;
  String? _lastSyncError;
  String? _clockSkewMs;
  int _pendingEvents = 0;
  bool _isSyncing = false;
  bool _hasRefreshToken = false;
  String? _syncResult;
  List<Session> _recentSessions = [];
  bool _canUseFsi = true;
  bool _canScheduleExact = true;
  bool _canDrawOverlays = true;

  Map<String, GameProgress> _gameProgress = {};
  Map<CognitiveDomain, GenreReport> _genreReports = {};
  RestState _restState = const RestState(dayKey: '');
  int _playMinutesToday = 0;
  ProgressionSettings _progressionSettings = const ProgressionSettings();
  late final TextEditingController _restMinutesController = TextEditingController();
  bool _isRunningReview = false;
  String? _reviewStatusMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _restMinutesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadProgressionData();

    try {
      _patientId = await _db.appConfigsDao.getValue('patientId');
      _deviceUserId = await _db.appConfigsDao.getValue('deviceUserId');
      _contentVersion = await _contentRepo.getContentVersion();
      _lastSyncAt = await _db.appConfigsDao.getValue('lastSyncAt');
      _lastSyncError = await _db.appConfigsDao.getValue('lastSyncError');
      _clockSkewMs = await _db.appConfigsDao.getValue('clockSkewMs');
      _pendingEvents = await _eventRepo.unsyncedCount();
      final token = await _db.appConfigsDao.getValue('deviceRefreshToken');
      _hasRefreshToken = token != null && token.isNotEmpty;
    } catch (_) {}

    if (Platform.isAndroid) {
      try {
        _canUseFsi = await NativeReminderBridge.canUseFullScreenIntent();
        _canScheduleExact = await NativeReminderBridge.canScheduleExactAlarms();
        _canDrawOverlays = await Permission.systemAlertWindow.isGranted;
      } catch (_) {}
    }

    try {
      _recentSessions = await _eventRepo.getRecentSessions(limit: 20);
    } catch (_) {}

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadProgressionData() async {
    try {
      final progService = _progressionService;
      final progressMap = <String, GameProgress>{};
      for (final gid in kGameDomains.keys) {
        progressMap[gid] = await progService.repo.getGameProgress(gid);
      }
      _gameProgress = progressMap;
      _genreReports = await progService.genreReports(windowDays: 7);
      final todayKey = PlayPolicy.dayKeyOf(DateTime.now());
      _restState = await progService.repo.getRestState(todayKey);
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final sessionsToday = await _eventRepo.sessionsBetween(
        startOfDay.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
      final playSec = PlayPolicy.playSecondsToday(sessionsToday);
      _playMinutesToday = PlayPolicy.displayMinutes(playSec);
      _progressionSettings = await progService.repo.getSettings();
      _restMinutesController.text = _progressionSettings.effectiveDailyRestMinutes.toString();
    } catch (_) {}
  }

  Future<void> _runSync() async {
    setState(() {
      _isSyncing = true;
      _syncResult = null;
    });

    final result = await _syncEngine.run(trigger: SyncTrigger.manual);
    
    setState(() {
      _isSyncing = false;
      _syncResult = result.hasErrors ? result.errorSummary : 'Sync completed successfully';
    });

    // Reload data
    await _loadData();
  }

  Future<void> _rePairDevice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Re-pair Tablet?'),
        content: const Text(
          'This will clear the current device registration and open the pairing screen. Existing game records will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracotta,
              foregroundColor: AppColors.onColor,
            ),
            child: const Text('Re-pair'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await appDatabase.appConfigsDao.deleteValue('patientId');
      await appDatabase.appConfigsDao.deleteValue('deviceUserId');
      await appDatabase.appConfigsDao.deleteValue('deviceRefreshToken');
      await appDatabase.appConfigsDao.deleteValue('contentVersion');
      await appDatabase.appConfigsDao.deleteValue('contentPatientId');
      await appDatabase.appConfigsDao.deleteValue('elderName');

      // Clear previous patient's cached content tables
      await appDatabase.delete(appDatabase.people).go();
      await appDatabase.delete(appDatabase.medications).go();
      await appDatabase.delete(appDatabase.routineItems).go();
      await appDatabase.delete(appDatabase.voiceMemos).go();
      await appDatabase.delete(appDatabase.reminderEvents).go();
      await appDatabase.delete(appDatabase.sessions).go();
      await appDatabase.delete(appDatabase.trialEvents).go();

      SyncEngine.resetDefaultInstance();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  /// Fires a test reminder through the real alarm → ReminderActivity path.
  /// It writes no ReminderEvent, so nothing reaches the caregiver.
  Future<void> _fireTestReminder() async {
    try {
      await scheduleTestReminder(delay: const Duration(seconds: 5));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Test alarm in 5s! Lock your screen now to verify full-screen alert & voice playback.',
            ),
            backgroundColor: AppColors.leafGreen,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule test reminder: $e'),
            backgroundColor: AppColors.terracottaDark,
          ),
        );
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
        title: const Text('Diagnostics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Info Section
              _buildSectionTitle('Device Information'),
              _buildInfoRow('Patient ID', _patientId ?? 'Not set'),
              _buildInfoRow('Device User ID', _deviceUserId ?? 'Not set'),
              const SizedBox(height: 8),
              
              // Content Section
              _buildSectionTitle('Content'),
              _buildInfoRow('Content Version', _contentVersion ?? 'Not set'),
              const SizedBox(height: 8),
              
              // Sync Section
              _buildSectionTitle('Sync Status'),
              _buildInfoRow('Last Sync', _formatTimestamp(_lastSyncAt)),
              _buildInfoRow('Last Sync Error', _lastSyncError ?? 'None'),
              _buildInfoRow('Pending Events', _pendingEvents.toString()),
              _buildInfoRow('Clock Skew', _clockSkewMs != null ? '$_clockSkewMs ms' : 'Unknown'),
              _buildInfoRow('Has Refresh Token', _hasRefreshToken ? 'Yes' : 'No (Requires Re-pairing)'),
              const SizedBox(height: 8),
              
              // Sync Actions
              _buildSectionTitle('Sync Actions'),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSyncing ? null : _runSync,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        foregroundColor: AppColors.onColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSyncing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : const Text('Run Sync Now'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _rePairDevice,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.terracotta,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppColors.terracotta),
                    ),
                    child: const Text('Re-pair Device'),
                  ),
                ],
              ),
              if (_syncResult != null) ...[
                const SizedBox(height: 12),
                Text(
                  _syncResult!,
                  style: TextStyle(
                    color: _syncResult!.contains('successfully') 
                        ? AppColors.leafGreen
                        : AppColors.terracottaDark,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              
              // Reminder Test Section
              _buildSectionTitle('Reminders & Permissions'),
              _buildInfoRow(
                'Display Over Other Apps',
                _canDrawOverlays
                    ? 'Granted'
                    : 'Off (unlocked phone gets a banner, not full screen)',
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => ReminderSetupScreen(
                        onDone: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  );
                  await _loadData();
                },
                icon: const Icon(Icons.checklist_rounded, size: 18),
                label: const Text('Open Reminder Setup'),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Full-Screen Intent (Lock Screen)',
                _canUseFsi ? 'Granted' : 'Revoked (Android 14+)',
              ),
              if (!_canUseFsi) ...[
                const SizedBox(height: 6),
                ElevatedButton.icon(
                  onPressed: () async {
                    await NativeReminderBridge.openFullScreenIntentSettings();
                    await Future.delayed(const Duration(seconds: 1));
                    await _loadData();
                  },
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Grant Full-Screen Intent in Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.marigoldDark,
                    foregroundColor: AppColors.onColor,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              _buildInfoRow(
                'Exact Alarms',
                _canScheduleExact ? 'Granted' : 'Revoked (Requires Special Access)',
              ),
              if (!_canScheduleExact) ...[
                const SizedBox(height: 6),
                ElevatedButton.icon(
                  onPressed: () async {
                    await NativeReminderBridge.openExactAlarmSettings();
                    await Future.delayed(const Duration(seconds: 1));
                    await _loadData();
                  },
                  icon: const Icon(Icons.alarm, size: 18),
                  label: const Text('Grant Exact Alarm Permission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.marigoldDark,
                    foregroundColor: AppColors.onColor,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
              Text(
                'Schedule a 5-second test reminder to verify that full-screen alerts appear over the lock screen and play voice audio.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _fireTestReminder,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.terracotta,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppColors.terracotta, width: 2),
                      ),
                      icon: const Icon(Icons.notification_important_rounded),
                      label: const Text(
                        'Schedule 5s Lock-Screen Test',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Next Alarms Section
              _buildSectionTitle('Next Scheduled Alarms'),
              Text(
                'Alarms will appear here when medications are scheduled.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 20),

              // Game Play Activity Section
              _buildSectionTitle('Game Play Activity'),
              _buildGameActivity(),
              const SizedBox(height: 8),

              // Game levels Section (docs/PROGRESSION_PLAN.md §11)
              _buildSectionTitle('Game levels'),
              _buildGameLevels(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameActivity() {
    if (_recentSessions.isEmpty) {
      return Text(
        'No games played yet on this device.',
        style: TextStyle(fontSize: 14, color: AppColors.secondaryText),
      );
    }

    int totalPlaySeconds = 0;
    for (final s in _recentSessions) {
      if (s.abandonedAtMs != null) {
        totalPlaySeconds += s.abandonedAtMs! ~/ 1000;
      } else if (s.endedAt != null && s.endedAt! > s.startedAt) {
        totalPlaySeconds += (s.endedAt! - s.startedAt) ~/ 1000;
      }
    }
    final totalMins = totalPlaySeconds ~/ 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Total Sessions: ${_recentSessions.length}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(width: 20),
            Text(
              'Total Time: ${totalMins}m',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.leafGreen),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._recentSessions.take(5).map((s) {
          final dt = DateTime.fromMillisecondsSinceEpoch(s.startedAt);
          final timeStr = '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
          final durationSec = s.abandonedAtMs != null
              ? s.abandonedAtMs! ~/ 1000
              : (s.endedAt != null && s.endedAt! > s.startedAt)
                  ? (s.endedAt! - s.startedAt) ~/ 1000
                  : 0;
          final durStr = durationSec >= 60
              ? '${durationSec ~/ 60}m ${durationSec % 60}s'
              : '${durationSec}s';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.gameIds.replaceAll('_', ' '),
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                ),
                Text(
                  durStr,
                  style: const TextStyle(fontSize: 13, color: AppColors.primaryText),
                ),
                const SizedBox(width: 12),
                Text(
                  '${dt.day}/${dt.month} $timeStr',
                  style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String? timestampMs) {
    if (timestampMs == null) return 'Never';
    
    try {
      final ms = int.tryParse(timestampMs) ?? 0;
      final date = DateTime.fromMillisecondsSinceEpoch(ms);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'.trim();
    } catch (_) {
      return 'Invalid';
    }
  }

  // ── Game levels section (docs/PROGRESSION_PLAN.md §11) ───────────────────

  Widget _buildGameLevels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Today's play summary
        _buildInfoRow('Today\'s Play Time', '$_playMinutesToday minutes'),
        _buildInfoRow('Rest Card Shown Today', '${_restState.shownCount} times'),
        _buildInfoRow('Keep Playing Chosen', '${_restState.keptPlayingCount} times'),
        const SizedBox(height: 12),

        // Rest reminder setting
        Row(
          children: [
            const Expanded(
              child: Text(
                'Rest reminder after (minutes):',
                style: TextStyle(fontSize: 14, color: AppColors.secondaryText),
              ),
            ),
            SizedBox(
              width: 70,
              child: TextField(
                key: const ValueKey('daily_rest_minutes_field'),
                controller: _restMinutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onSubmitted: _saveRestMinutes,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              key: const ValueKey('save_daily_rest_minutes'),
              onPressed: () => _saveRestMinutes(_restMinutesController.text),
              child: const Text('Save'),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Run review now button
        ElevatedButton.icon(
          onPressed: _isRunningReview ? null : _runReviewsNow,
          icon: _isRunningReview
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Run review now'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.terracotta,
            foregroundColor: AppColors.onColor,
          ),
        ),
        if (_reviewStatusMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            _reviewStatusMessage!,
            style: const TextStyle(fontSize: 13, color: AppColors.leafGreen),
          ),
        ],
        const SizedBox(height: 18),

        // "By genre" mini table
        const Text(
          'By genre',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryText),
        ),
        const SizedBox(height: 8),
        _buildGenreTable(),
        const SizedBox(height: 18),

        // Per-game list
        const Text(
          'Games',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryText),
        ),
        const SizedBox(height: 8),
        ...gameCatalog.map((info) => _buildGameRow(info)),
      ],
    );
  }

  Widget _buildGenreTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.5),
      },
      border: TableBorder.all(color: AppColors.border, width: 1),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.04)),
          children: const [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Domain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Games Played', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Weighted Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        ...CognitiveDomain.values.map((domain) {
          final report = _genreReports[domain];
          final played = report?.gamesPlayed ?? 0;
          final scoreStr = report?.meanScore != null
              ? '${(report!.meanScore! * 100).round()}%'
              : '-';
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  domain.name[0].toUpperCase() + domain.name.substring(1),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('$played', style: const TextStyle(fontSize: 13)),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(scoreStr, style: const TextStyle(fontSize: 13)),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildGameRow(GameInfo info) {
    final progress = _gameProgress[info.id] ?? GameProgress.fresh(info.id);
    final profile = GameLevelProfiles.byGameId[info.id];
    final plateauLevel = profile?.plateauLevel ?? 40.0;
    final lastRecord = progress.history.isNotEmpty ? progress.history.last : null;
    final concern = lastRecord?.concern ?? false;

    final levelStr = progress.level.toStringAsFixed(1);
    final plateauStr = plateauLevel.toStringAsFixed(1);
    final reviewDateStr = _formatReviewDate(progress.lastReviewAtMs);
    final decisionStr = _decisionText(lastRecord?.decision);
    final scoreStr = (lastRecord != null && lastRecord.score != null)
        ? '${(lastRecord.score! * 100).round()}%'
        : '-';
    final trialsStr = lastRecord != null ? '${lastRecord.trials}' : '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  info.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              if (concern)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.marigold.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Needs attention',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _buildMetricChip('Level', levelStr),
              _buildMetricChip('Plateau', plateauStr),
              _buildMetricChip('Last Review', reviewDateStr),
              _buildMetricChip('Decision', decisionStr),
              _buildMetricChip('Last Score', scoreStr),
              _buildMetricChip('Trials in Window', trialsStr),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              key: ValueKey('reset_level_${info.id}'),
              onPressed: () => _confirmResetLevel(info.id, info.name),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Reset level', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
        const SizedBox(height: 1),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
      ],
    );
  }

  String _decisionText(ReviewDecision? decision) {
    switch (decision) {
      case ReviewDecision.raise:
      case ReviewDecision.nudgeUp:
        return 'Raised';
      case ReviewDecision.hold:
        return 'Kept the same';
      case ReviewDecision.ease:
      case ReviewDecision.easeMore:
        return 'Made easier';
      case ReviewDecision.returning:
        return 'Welcome back, eased';
      case ReviewDecision.notEnoughData:
      case null:
        return 'Not enough play yet';
    }
  }

  String _formatReviewDate(int? ms) {
    if (ms == null) return 'Never';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveRestMinutes(String text) async {
    final minutes = int.tryParse(text.trim());
    if (minutes == null || minutes < 0) return;
    final updated = _progressionSettings.copyWith(dailyRestMinutes: minutes);
    await _progressionService.repo.saveSettings(updated);
    if (!mounted) return;
    setState(() => _progressionSettings = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rest reminder set to $minutes minutes')),
    );
  }

  Future<void> _runReviewsNow() async {
    setState(() {
      _isRunningReview = true;
      _reviewStatusMessage = null;
    });

    try {
      await _progressionService.runDueReviews(force: true);
      await _loadProgressionData();
      if (!mounted) return;
      setState(() {
        _isRunningReview = false;
        _reviewStatusMessage = 'Reviews completed';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRunningReview = false;
        _reviewStatusMessage = 'Review failed: $e';
      });
    }
  }

  Future<void> _confirmResetLevel(String gameId, String gameName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Level for $gameName?'),
        content: Text(
          'Reset level for $gameName back to its starting value?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracotta,
              foregroundColor: AppColors.onColor,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _resetLevel(gameId);
    }
  }

  Future<void> _resetLevel(String gameId) async {
    final domain = kGameDomains[gameId] ?? CognitiveDomain.executive;
    final allProgress = await _progressionService.allProgress();
    final others = <GameProgress>[];
    for (final otherId in kGameDomains.keys) {
      if (otherId == gameId || kGameDomains[otherId] != domain) continue;
      final otherProgress = allProgress[otherId];
      if (otherProgress != null && otherProgress.seeded) others.add(otherProgress);
    }

    double thetaBasedLevel;
    try {
      final record = await _progressionService.abilityRepo.getOrSeed(domain);
      thetaBasedLevel = LevelScale.difficultyToLevel(AbilityEstimator.nextDifficulty(record.theta));
    } catch (_) {
      thetaBasedLevel = ProgressionConfig.minLevel;
    }

    final startLevel = ProgressionPolicy.startingLevel(
      domain: domain,
      otherSeededGamesInDomain: others,
      thetaBasedLevel: thetaBasedLevel,
    );

    final current = await _progressionService.repo.getGameProgress(gameId);
    final updated = current.copyWith(
      level: startLevel,
      seeded: true,
    );
    await _progressionService.repo.saveGameProgress(updated);
    await _loadProgressionData();
    if (!mounted) return;
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Level for ${_gameName(gameId)} reset to ${startLevel.toStringAsFixed(1)}')),
    );
  }

  String _gameName(String gameId) {
    return gameInfoFor(gameId)?.name ?? gameId;
  }
}
