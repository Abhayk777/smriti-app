import 'dart:io';

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
  }) : _patientId = patientId;

  final SmritiDatabase db;
  final MemoRepo memoRepo;
  String? _patientId;

  /// Patient ID from AppConfigs - will be read when needed
  Future<String> _getPatientId() async {
    return _patientId ??= 
        await db.appConfigsDao.getValue('patientId') ?? 
        (throw Exception('No patientId configured'));
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
      
      for (final memo in pendingMemos) {
        // Upload the audio file first
        final localPath = memo.localPath;
        final file = File(localPath);
        
        if (!await file.exists()) {
          // File missing locally - mark as uploaded to avoid retrying
          failedCount++;
          continue;
        }
        
        try {
          // Upload to Supabase storage
          final fileName = 'memos/${memo.id}.m4a';
          await Supabase.instance.client.storage
              .from(_memosBucket)
              .upload(fileName, file);
          
          // Only create the row if storage upload succeeded
          await Supabase.instance.client.from('memos').upsert({
            'id': memo.id,
            'patient_id': pid,
            'local_path': memo.localPath,
            'duration_ms': memo.durationMs,
            'recorded_at': memo.recordedAt,
            'context_tag': memo.contextTag,
            'uploaded': true,
          }, onConflict: 'id', ignoreDuplicates: true);
          
          // Mark as uploaded locally
          await memoRepo.markUploaded([memo.id]);
          uploadedCount++;
          
        } catch (e) {
          // Storage upload failed - don't create row
          failedCount++;
        }
      }
      
      return MemoUploadResult(
        uploadedCount: uploadedCount,
        failedCount: failedCount,
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
      await Supabase.instance.client.from('memos').upsert({
        'id': memo.id,
        'patient_id': pid,
        'local_path': memo.localPath,
        'duration_ms': memo.durationMs,
        'recorded_at': memo.recordedAt,
        'context_tag': memo.contextTag,
        'uploaded': true,
      }, onConflict: 'id', ignoreDuplicates: true);
      
      // Mark as uploaded locally
      await memoRepo.markUploaded([memo.id]);
      
      return true;
      
    } catch (_) {
      return false;
    }
  }
}
