import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/database.dart';
import '../repo/memo_repo.dart';

/// Result of a memo upload operation.
class MemoUploadResult {
  const MemoUploadResult({
    required this.uploadedCount,
    required this.failedCount,
    this.error,
  });

  final int uploadedCount;
  final int failedCount;
  final String? error;

  bool get success => failedCount == 0;
}

/// Uploads elder voice memos to Supabase storage and creates memo metadata rows.
///
/// Per APP-BUILD-SPEC.md §9.4: Storage upload first, then the memos row insert.
/// A row pointing at a file that never uploaded is worse than a file with no row.
/// Only this class may import supabase_flutter outside core/auth (AGENTS.md #1).
class MemoUploader {
  MemoUploader({
    required this.db,
    required this.memoRepo,
    String? patientId,
  });

  final SmritiDatabase db;
  final MemoRepo memoRepo;

  /// Patient ID from AppConfigs - will be read when needed
  Future<String> _getPatientId() async {
    final jwtPid = Supabase.instance.client.auth.currentUser?.appMetadata['patient_id'];
    if (jwtPid is String && jwtPid.isNotEmpty) {
      return jwtPid;
    }
    final configPid = await db.appConfigsDao.getValue('patientId');
    if (configPid != null && configPid.isNotEmpty) {
      return configPid;
    }
    throw Exception('No patientId configured');
  }

  /// Storage bucket for elder voice memos
  static const String _memosBucket = 'patient-memos';

  /// Uploads all pending voice memos to Supabase.
  ///
  /// Uploads storage first, then creates the row. This ensures we never have
  /// a database row pointing to a non-existent file.
  Future<MemoUploadResult> upload() async {
    try {
      final pid = await _getPatientId();
      final pendingMemos = await memoRepo.pendingUploads(limit: 50);
      
      int uploadedCount = 0;
      int failedCount = 0;
      String? lastError;
      
      for (final memo in pendingMemos) {
        // Upload the audio file first
        final localPath = memo.localPath;
        final file = File(localPath);
        
        if (!await file.exists()) {
          // File missing locally - mark as uploaded to avoid retrying
          await memoRepo.markUploaded([memo.id]);
          continue;
        }
        
        try {
          // Upload to Supabase storage - path convention {patient_id}/{filename}
          final storagePath = '$pid/${memo.id}.m4a';
          try {
            await Supabase.instance.client.storage
                .from(_memosBucket)
                .upload(
                  storagePath,
                  file,
                  fileOptions: const FileOptions(
                    contentType: 'audio/m4a',
                  ),
                );
          } catch (storageErr) {
            final errStr = storageErr.toString().toLowerCase();
            // If the file is already uploaded in storage, proceed to create row
            if (!errStr.contains('already exists') &&
                !errStr.contains('409') &&
                !errStr.contains('duplicate')) {
              rethrow;
            }
          }
          
          // Create the row in memos table
          try {
            await Supabase.instance.client.from('memos').insert({
              'id': memo.id,
              'patient_id': pid,
              'storage_path': storagePath,
              'duration_ms': memo.durationMs,
              'recorded_at': memo.recordedAt,
              'context_tag': memo.contextTag,
            });
          } catch (rowErr) {
            final errStr = rowErr.toString().toLowerCase();
            if (!errStr.contains('duplicate') && !errStr.contains('23505')) {
              rethrow;
            }
          }
          
          // Mark as uploaded locally
          await memoRepo.markUploaded([memo.id]);
          uploadedCount++;
          
        } catch (e) {
          lastError = e.toString();
          debugPrint('Memo upload error: $e');
          failedCount++;
        }
      }
      
      return MemoUploadResult(
        uploadedCount: uploadedCount,
        failedCount: failedCount,
        error: failedCount > 0 ? (lastError ?? 'Failed to upload $failedCount memos') : null,
      );
      
    } catch (e) {
      return MemoUploadResult(
        uploadedCount: 0,
        failedCount: 0,
        error: e.toString(),
      );
    }
  }

  /// Uploads a single memo file.
  Future<bool> uploadSingle(String memoId) async {
    try {
      final memo = await memoRepo.getMemo(memoId);
      if (memo == null) return false;
      
      final localPath = memo.localPath;
      final file = File(localPath);
      
      if (!await file.exists()) {
        return false;
      }
      
      final pid = await _getPatientId();
      final fileName = 'memos/${memo.id}.m4a';
      
      // Upload to storage
      await Supabase.instance.client.storage
          .from(_memosBucket)
          .upload(fileName, file);
      
      // Create metadata row
      await Supabase.instance.client.from('memos').insert({
        'id': memo.id,
        'patient_id': pid,
        'storage_path': fileName,
        'duration_ms': memo.durationMs,
        'recorded_at': memo.recordedAt,
        'context_tag': memo.contextTag,
      });
      
      // Mark as uploaded locally
      await memoRepo.markUploaded([memo.id]);
      
      return true;
      
    } catch (_) {
      return false;
    }
  }
}
