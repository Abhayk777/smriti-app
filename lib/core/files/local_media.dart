import 'dart:io';

import 'package:path/path.dart' as p;

import 'file_paths.dart';

const photoExtensions = ['.jpg', '.jpeg', '.png'];
const voiceExtensions = ['.m4a', '.mp3', '.aac', '.wav'];

/// Finds a downloaded media file on disk.
///
/// Tries the stored path first, then the same file name inside [getDir]
/// (the app directory can move between installs), then `<id><ext>` in that
/// directory. Returns null when nothing non-empty is found.
Future<File?> resolveLocalMedia(
  String rawPath,
  Future<String> Function() getDir,
  String id, [
  List<String> exts = photoExtensions,
]) async {
  if (rawPath.isNotEmpty) {
    final direct = File(rawPath);
    if (direct.existsSync() && direct.lengthSync() > 0) return direct;
  }
  final dir = await getDir();
  if (rawPath.isNotEmpty) {
    final byBase = File(p.join(dir, p.basename(rawPath)));
    if (byBase.existsSync() && byBase.lengthSync() > 0) return byBase;
  }
  for (final ext in exts) {
    final byId = File(p.join(dir, '$id$ext'));
    if (byId.existsSync() && byId.lengthSync() > 0) return byId;
  }
  return null;
}

/// Photo of a family member, as pulled into the People table.
Future<File?> resolvePersonPhoto(String rawPath, String personId) =>
    resolveLocalMedia(rawPath, FilePaths.peoplePhotos, personId);
