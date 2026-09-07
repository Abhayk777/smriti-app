import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
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
  /// The [remotePath] is the storage path from the backend (e.g., 'people/photos/abc123.jpg').
  Future<bool> downloadPeoplePhoto(String personId, String remotePath) async {
    try {
      final localPath = FilePaths.peoplePhoto(personId);
      final file = File(localPath);
      
      // Create parent directories if they don't exist
      await file.create(recursive: true);
      
      // Download from Supabase storage
      final data = await Supabase.instance.client.storage
          .from(_mediaBucket)
          .download(remotePath);
      
      // Write to local file
      await file.writeAsBytes(data, flush: true);
      
      // Verify file exists and has content
      if (await file.exists() && await file.length() > 0) {
        return true;
      }
      
      // Clean up if verification failed
      if (await file.exists()) {
        await file.delete();
      }
      return false;
      
    } catch (e) {
      // Log error but don't throw - caller handles partial failures
      return false;
    }
  }

  /// Downloads a person's voice recording from Supabase storage.
  Future<bool> downloadPeopleVoice(String personId, String remotePath) async {
    try {
      final localPath = FilePaths.peopleVoice(personId);
      final file = File(localPath);
      
      await file.create(recursive: true);
      
      final data = await Supabase.instance.client.storage
          .from(_mediaBucket)
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

  /// Downloads a medication's photo from Supabase storage.
  Future<bool> downloadMedicationPhoto(String medId, String remotePath) async {
    try {
      final localPath = FilePaths.medicationPhoto(medId);
      final file = File(localPath);
      
      await file.create(recursive: true);
      
      final data = await Supabase.instance.client.storage
          .from(_mediaBucket)
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

  /// Downloads a medication's voice reminder from Supabase storage.
  Future<bool> downloadMedicationVoice(String medId, String remotePath) async {
    try {
      final localPath = FilePaths.medicationVoice(medId);
      final file = File(localPath);
      
      await file.create(recursive: true);
      
      final data = await Supabase.instance.client.storage
          .from(_mediaBucket)
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

  /// Downloads language pack files.
  Future<bool> downloadLanguagePack(String langCode, String remotePath) async {
    try {
      final localPath = FilePaths.languagePackFile(langCode, remotePath);
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
      final personId = p['id'] as String;
      
      if (p['photo_path'] is String && (p['photo_path'] as String).isNotEmpty) {
        final file = File(FilePaths.peoplePhoto(personId));
        if (await file.exists() && await file.length() > 0) {
          verified++;
        }
      }
      
      if (p['voice_path'] is String && (p['voice_path'] as String).isNotEmpty) {
        final file = File(FilePaths.peopleVoice(personId));
        if (await file.exists() && await file.length() > 0) {
          verified++;
        }
      }
    }
    
    // Verify medications media
    for (final m in medicationsData) {
      final medId = m['id'] as String;
      
      if (m['pill_photo_path'] is String && (m['pill_photo_path'] as String).isNotEmpty) {
        final file = File(FilePaths.medicationPhoto(medId));
        if (await file.exists() && await file.length() > 0) {
          verified++;
        }
      }
      
      if (m['voice_path'] is String && (m['voice_path'] as String).isNotEmpty) {
        final file = File(FilePaths.medicationVoice(medId));
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
      final tempDir = Directory(FilePaths.tempDir);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {
      // Ignore cleanup errors
    }
  }
}
