import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FilePaths {
  static Future<String> _documentsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<String> _ensureDirectory(String path) async {
    final directory = Directory(path);

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory.path;
  }

  static Future<String> peoplePhotos() async {
    final root = await _documentsDirectory();
    return _ensureDirectory(p.join(root, 'people', 'photos'));
  }

  static Future<String> peopleVoice() async {
    final root = await _documentsDirectory();
    return _ensureDirectory(p.join(root, 'people', 'voice'));
  }

  static Future<String> medicationPhotos() async {
    final root = await _documentsDirectory();
    return _ensureDirectory(p.join(root, 'medications', 'photos'));
  }

  static Future<String> medicationVoice() async {
    final root = await _documentsDirectory();
    return _ensureDirectory(p.join(root, 'medications', 'voice'));
  }

  static Future<String> languagePacks() async {
    final root = await _documentsDirectory();
    return _ensureDirectory(p.join(root, 'language_packs'));
  }

  static Future<String> memos() async {
    final root = await _documentsDirectory();
    return _ensureDirectory(p.join(root, 'memos'));
  }

  static Future<String> temporary() async {
    final root = await _documentsDirectory();
    return _ensureDirectory(p.join(root, 'tmp'));
  }
}