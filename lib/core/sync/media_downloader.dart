import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/database.dart';
import '../files/file_paths.dart';

/// Result of a media download operation.
class MediaDownloadResult {
  const MediaDownloadResult({
    required this.success,
    this.filePath,
    this.error,
  });

  final bool success;
  final String? filePath;
  final String? error;
}

/// Downloads and verifies media files from Supabase storage.
///
/// Per AGENTS.md non-negotiable #5: Media is downloaded BEFORE the atomic DB swap.
/// Only this class may import supabase_flutter outside core/auth (AGENTS.md #1).
class MediaDownloader {
  MediaDownloader(this.db);

  final SmritiDatabase db;

  /// Base URL for patient media storage bucket
  static const String _mediaBucket = 'patient-media';

  /// Downloads a person's photo from Supabase storage.
  ///
  /// Returns the local file path on success, or null on failure.
  Future<String?> downloadPeoplePhoto(String personId, String remotePath) async {
    try {
      final cleanPath = remotePath.startsWith('/') ? remotePath.substring(1) : remotePath;
      final dir = await FilePaths.peoplePhotos();
      final ext = path.extension(cleanPath).isNotEmpty ? path.extension(cleanPath) : '.jpg';
      final localPath = path.join(dir, '$personId$ext');
      final file = File(localPath);
      
      // Also save by basename
      final baseFile = File(path.join(dir, path.basename(cleanPath)));
      
      await file.create(recursive: true);
      
      debugPrint('[MediaDownloader] Downloading people photo from $_mediaBucket/$cleanPath to $localPath');
      final data = await Supabase.instance.client.storage
          .from(_mediaBucket)
          .download(cleanPath);
      
      await file.writeAsBytes(data, flush: true);
      try {
        await baseFile.writeAsBytes(data, flush: true);
      } catch (_) {}
      
      if (await file.exists() && await file.length() > 0) {
        debugPrint('[MediaDownloader] Successfully downloaded people photo: $localPath (${data.length} bytes)');
        return localPath;
      }
      return null;
    } catch (e) {
      debugPrint('[MediaDownloader] Failed to download people photo ($remotePath): $e');
      return null;
    }
  }

  /// Downloads a person's voice recording from Supabase storage.
  Future<String?> downloadPeopleVoice(String personId, String remotePath) async {
    try {
      final cleanPath = remotePath.startsWith('/') ? remotePath.substring(1) : remotePath;
      final dir = await FilePaths.peopleVoice();
      final ext = path.extension(cleanPath).isNotEmpty ? path.extension(cleanPath) : '.m4a';
      final localPath = path.join(dir, '$personId$ext');
      final file = File(localPath);
      final baseFile = File(path.join(dir, path.basename(cleanPath)));
      
      await file.create(recursive: true);
      
      debugPrint('[MediaDownloader] Downloading people voice from $_mediaBucket/$cleanPath to $localPath');
      final data = await Supabase.instance.client.storage
          .from(_mediaBucket)
          .download(cleanPath);
      
      await file.writeAsBytes(data, flush: true);
      try {
        await baseFile.writeAsBytes(data, flush: true);
      } catch (_) {}
      
      if (await file.exists() && await file.length() > 0) {
        debugPrint('[MediaDownloader] Successfully downloaded people voice: $localPath');
        return localPath;
      }
      return null;
    } catch (e) {
      debugPrint('[MediaDownloader] Failed to download people voice ($remotePath): $e');
      return null;
    }
  }

  /// Downloads a medication's photo from Supabase storage.
  Future<String?> downloadMedicationPhoto(String medId, String remotePath) async {
    try {
      final cleanPath = remotePath.startsWith('/') ? remotePath.substring(1) : remotePath;
      final dir = await FilePaths.medicationPhotos();
      final ext = path.extension(cleanPath).isNotEmpty ? path.extension(cleanPath) : '.jpg';
      final localPath = path.join(dir, '$medId$ext');
      final file = File(localPath);
      final baseFile = File(path.join(dir, path.basename(cleanPath)));
      
      await file.create(recursive: true);
      
      debugPrint('[MediaDownloader] Downloading medication photo from $_mediaBucket/$cleanPath to $localPath');
      final data = await Supabase.instance.client.storage
          .from(_mediaBucket)
          .download(cleanPath);
      
      await file.writeAsBytes(data, flush: true);
      try {
        await baseFile.writeAsBytes(data, flush: true);
      } catch (_) {}
      
      if (await file.exists() && await file.length() > 0) {
        debugPrint('[MediaDownloader] Successfully downloaded medication photo: $localPath');
        return localPath;
      }
      return null;
    } catch (e) {
      debugPrint('[MediaDownloader] Failed to download medication photo ($remotePath): $e');
      return null;
    }
  }

  /// Downloads a medication's voice reminder from Supabase storage.
  Future<String?> downloadMedicationVoice(String medId, String remotePath) async {
    try {
      final cleanPath = remotePath.startsWith('/') ? remotePath.substring(1) : remotePath;
      final dir = await FilePaths.medicationVoice();
      final ext = path.extension(cleanPath).isNotEmpty ? path.extension(cleanPath) : '.m4a';
      final localPath = path.join(dir, '$medId$ext');
      final file = File(localPath);
      final baseFile = File(path.join(dir, path.basename(cleanPath)));
      
      await file.create(recursive: true);
      
      debugPrint('[MediaDownloader] Downloading medication voice from $_mediaBucket/$cleanPath to $localPath');
      final data = await Supabase.instance.client.storage
          .from(_mediaBucket)
          .download(cleanPath);
      
      await file.writeAsBytes(data, flush: true);
      try {
        await baseFile.writeAsBytes(data, flush: true);
      } catch (_) {}
      
      if (await file.exists() && await file.length() > 0) {
        debugPrint('[MediaDownloader] Successfully downloaded medication voice: $localPath');
        return localPath;
      }
      return null;
    } catch (e) {
      debugPrint('[MediaDownloader] Failed to download medication voice ($remotePath): $e');
      return null;
    }
  }

  /// Downloads language pack files.
  Future<bool> downloadLanguagePack(String langCode, String remotePath) async {
    try {
      final dir = await FilePaths.languagePacks();
      final filename = path.basename(remotePath);
      final localPath = path.join(dir, filename);
      final file = File(localPath);
      
      await file.create(recursive: true);
      
      final data = await Supabase.instance.client.storage
          .from('lang-packs')
          .download(remotePath);
      
      await file.writeAsBytes(data, flush: true);
      
      if (await file.exists() && await file.length() > 0) {
        return true;
      }
      
      if (await file.exists()) {
        await file.delete();
      }
      return false;
      
    } catch (e) {
      return false;
    }
  }

  /// Verifies that all expected media files exist on disk.
  ///
  /// Returns the count of verified files. This must match the number of
  /// downloaded files before the atomic DB swap can proceed (AGENTS.md #5).
  Future<int> verifyAllMedia(
    List<Map<String, dynamic>> peopleData,
    List<Map<String, dynamic>> medicationsData,
  ) async {
    int verified = 0;
    
    // Verify people media
    for (final p in peopleData) {
      if (p['photo_path'] is String && (p['photo_path'] as String).isNotEmpty) {
        final remotePath = p['photo_path'] as String;
        final dir = await FilePaths.peoplePhotos();
        final filename = path.basename(remotePath);
        final filePath = path.join(dir, filename);
        final file = File(filePath);
        if (await file.exists() && await file.length() > 0) {
          verified++;
        }
      }
      
      if (p['voice_path'] is String && (p['voice_path'] as String).isNotEmpty) {
        final remotePath = p['voice_path'] as String;
        final dir = await FilePaths.peopleVoice();
        final filename = path.basename(remotePath);
        final filePath = path.join(dir, filename);
        final file = File(filePath);
        if (await file.exists() && await file.length() > 0) {
          verified++;
        }
      }
    }
    
    // Verify medications media
    for (final m in medicationsData) {
      if (m['pill_photo_path'] is String && (m['pill_photo_path'] as String).isNotEmpty) {
        final remotePath = m['pill_photo_path'] as String;
        final dir = await FilePaths.medicationPhotos();
        final filename = path.basename(remotePath);
        final filePath = path.join(dir, filename);
        final file = File(filePath);
        if (await file.exists() && await file.length() > 0) {
          verified++;
        }
      }
      
      if (m['voice_path'] is String && (m['voice_path'] as String).isNotEmpty) {
        final remotePath = m['voice_path'] as String;
        final dir = await FilePaths.medicationVoice();
        final filename = path.basename(remotePath);
        final filePath = path.join(dir, filename);
        final file = File(filePath);
        if (await file.exists() && await file.length() > 0) {
          verified++;
        }
      }
    }
    
    return verified;
  }

  /// Verifies a specific file exists and has content.
  Future<bool> verifyFile(String filePath) async {
    final file = File(filePath);
    return await file.exists() && await file.length() > 0;
  }

  /// Cleans up temporary download files.
  Future<void> cleanupTempFiles() async {
    try {
      final tempDirPath = await FilePaths.temporary();
      final tempDir = Directory(tempDirPath);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {
      // Ignore cleanup errors
    }
  }
}
