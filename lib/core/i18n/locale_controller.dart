import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../db/database.dart';
import 'app_strings.dart';

/// Manages active application locale and synchronizes with local Drift SQLite.
///
/// 100% offline: all changes are immediate in-memory and committed to SQLite
/// AppConfigs, requiring 0ms latency and no network connection.
class LocaleController extends ChangeNotifier {
  LocaleController({SmritiDatabase? db, String defaultLanguage = 'en'})
      : _db = db ?? appDatabase,
        _langCode = defaultLanguage;

  final SmritiDatabase _db;
  static LocaleController? _instance;

  static LocaleController get instance => _instance ??= LocaleController();

  String _langCode;

  String get currentLanguage => _langCode;
  LanguageMeta get currentMeta => AppStrings.metaFor(_langCode);

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Loads the saved language from local SQLite on startup.
  Future<void> init() async {
    if (_initialized) return;
    try {
      final saved = await _db.appConfigsDao.getValue('langCode');
      if (saved != null && saved.isNotEmpty) {
        _langCode = saved;
      }
    } catch (_) {}
    _initialized = true;
    notifyListeners();
  }

  /// Sets active language in memory, notifies all listening widgets immediately,
  /// and persists to SQLite.
  Future<void> setLanguage(String newCode) async {
    if (_langCode == newCode) return;
    _langCode = newCode;
    notifyListeners();

    try {
      await _db.appConfigsDao.setValue('langCode', newCode);
    } catch (_) {}
  }
}
