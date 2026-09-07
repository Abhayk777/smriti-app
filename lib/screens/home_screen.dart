import 'dart:io';

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../core/app_services.dart';
import '../core/db/database.dart';
import '../core/sync/sync_engine.dart';
import '../games/game_content_loader.dart';
import '../games/market_basket/market_basket_screen.dart';
import 'debug_sheet.dart';

/// Deliberately plain home screen.
///
/// This exists so pairing leads somewhere, so a reminder has somewhere to
/// return the elder to, and so real pulled content can be seen in the running
/// app. Elder-facing visual design is a separate concern — nothing here is a
/// proposal for how the real home screen should look.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _data = _load();

  Future<_HomeData> _load() async {
    final services = widget.services;
    return _HomeData(
      elderName: await services.db.appConfigsDao.getValue('elderName') ?? '',
      contentVersion: await services.contentRepo.getContentVersion(),
      medications: await services.contentRepo.getMedications(),
      routineItems: await services.contentRepo.getRoutineItems(),
      people: await services.contentRepo.getPeople(),
    );
  }

  Future<void> _refresh() async {
    // Pull, then redraw with whatever landed.
    await widget.services.syncEngine.run(trigger: SyncTrigger.manual);
    if (mounted) setState(() => _data = _load());
  }

  Future<void> _playMarketBasket() async {
    // Market goods are not part of pulled content yet, so the catalogue still
    // comes from the bundled mock JSON.
    final content = await loadMockGameContent();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MarketBasketScreen(
          services: widget.services,
          content: content,
        ),
      ),
    );
    // A finished session should sync straight away (APP-BUILD-SPEC.md §9).
    await widget.services.syncEngine.run(trigger: SyncTrigger.sessionEnd);
  }

  /// Hidden access point, pulled forward from §12's diagnostics screen:
  /// long-press the title for the debug panel, which can fire a reminder now
  /// rather than waiting on a real dose window, and run the setup health check.
  Future<void> _openDebugSheet() => DebugSheet.show(context, widget.services);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: FutureBuilder<_HomeData>(
          future: _data,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                GestureDetector(
                  onLongPress: _openDebugSheet,
                  child: Text(
                    data.elderName.isEmpty ? 'Home' : data.elderName,
                    key: const Key('home_title'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                Text(
                  'content v${data.contentVersion ?? '-'} · '
                  '${data.people.length} people',
                  key: const Key('home_content_version'),
                  style: TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 20),

                // ROUTINE STRIP
                const Text('Today', style: TextStyle(fontWeight: FontWeight.w700)),
                if (data.routineItems.isEmpty)
                  const Text('No routine yet', key: Key('routine_empty'))
                else
                  SizedBox(
                    height: 70,
                    child: ListView(
                      key: const Key('routine_strip'),
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final item in data.routineItems)
                          Container(
                            key: Key('routine_${item.id}'),
                            width: 120,
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(8),
                            color: AppColors.raisedSurface,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_formatMinutes(item.timeMin)),
                                Text(
                                  item.labelKey,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // MEDICATIONS
                const Text('Medicines',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                if (data.medications.isEmpty)
                  const Text('No medicines yet', key: Key('medications_empty'))
                else
                  for (final medication in data.medications)
                    ListTile(
                      key: Key('medication_${medication.id}'),
                      contentPadding: EdgeInsets.zero,
                      title: Text('${medication.name} · ${medication.dose}'),
                      subtitle:
                          Text(_formatMinutes(medication.chosenTimeMin)),
                    ),
                const SizedBox(height: 24),

                ElevatedButton(
                  key: const Key('play_market_basket'),
                  onPressed: _playMarketBasket,
                  child: const Text('Play Market Basket'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  key: const Key('refresh_content'),
                  onPressed: _refresh,
                  child: const Text('Sync now'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _HomeData {
  const _HomeData({
    required this.elderName,
    required this.contentVersion,
    required this.medications,
    required this.routineItems,
    required this.people,
  });

  final String elderName;
  final String? contentVersion;
  final List<Medication> medications;
  final List<RoutineItem> routineItems;
  final List<PeopleData> people;
}

/// A local file, or null when the media never downloaded. Screens skip missing
/// media silently (APP-BUILD-SPEC.md §6).
File? existingFile(String? path) {
  if (path == null || path.isEmpty) return null;
  final file = File(path);
  return file.existsSync() ? file : null;
}
