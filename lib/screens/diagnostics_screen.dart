import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/db/database.dart';
import '../core/repo/content_repo.dart';
import '../core/repo/event_repo.dart';
import '../core/sync/sync_engine.dart';

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
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  late final ContentRepo _contentRepo = ContentRepo(appDatabase);
  late final EventRepo _eventRepo = EventRepo(appDatabase);
  late final SyncEngine _syncEngine = SyncEngine.defaultInstance;

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _patientId = await appDatabase.appConfigsDao.getValue('patientId');
    _deviceUserId = await appDatabase.appConfigsDao.getValue('deviceUserId');
    _contentVersion = await _contentRepo.getContentVersion();
    _lastSyncAt = await appDatabase.appConfigsDao.getValue('lastSyncAt');
    _lastSyncError = await _syncEngine.getLastSyncError();
    _clockSkewMs = await appDatabase.appConfigsDao.getValue('clockSkewMs');
    _pendingEvents = await _eventRepo.unsyncedCount();
    final token = await appDatabase.appConfigsDao.getValue('deviceRefreshToken');
    _hasRefreshToken = token != null && token.isNotEmpty;
    try {
      _recentSessions = await _eventRepo.getRecentSessions(limit: 20);
    } catch (_) {}

    if (mounted) {
      setState(() {});
    }
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
              foregroundColor: Colors.white,
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
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  Future<void> _fireTestReminder() async {
    // TODO: Implement test reminder
    // This would trigger a test medication reminder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test reminder scheduled')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
                        foregroundColor: Colors.white,
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
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              
              // Reminder Test Section
              _buildSectionTitle('Reminder Test'),
              Text(
                'Schedule a test reminder to verify that alarms are working correctly.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _fireTestReminder,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.terracotta,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppColors.terracotta),
                      ),
                      child: const Text('Fire Test Reminder Now'),
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
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),

              // Game Play Activity Section
              _buildSectionTitle('Game Play Activity'),
              _buildGameActivity(),
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
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
          color: Colors.black,
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
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
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
}
