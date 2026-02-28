// Phase 5: Forms & Attachments - File Chunking, Verification, Crash-Safe Resume
// Handles large file uploads with integrity checking and resumable uploads

import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Advanced Attachment Service with Chunking & Verification
class AdvancedAttachmentService {
  /// The size of each file chunk for upload.
  static const int chunkSize = 5 * 1024 * 1024; // 5MB chunks

  /// The maximum allowed file size for attachments.
  static const int maxFileSize = 500 * 1024 * 1024; // 500MB max

  /// The name of the storage bucket for uploads.
  static const String uploadsBucket = 'form-attachments';
  final SupabaseClient _supabase;

  /// Creates an [AdvancedAttachmentService] instance.
  AdvancedAttachmentService(this._supabase);

  /// Cancel upload and clean up
  Future<void> cancelUpload(String sessionId) async {
    try {
      await _clearUploadProgress(sessionId);
      await _supabase.rpc('cleanup_upload_session', params: {
        'session_id': sessionId,
      });
    } catch (e) {
      AppLogger.warning('Error canceling upload', error: e);
    }
  }

  /// Delete attachment and clean up
  Future<void> deleteAttachment(String attachmentId) async {
    try {
      // Delete from storage
      await _supabase.storage
          .from(uploadsBucket)
          .remove(['form-attachments/$attachmentId']);

      // Delete from database
      await _supabase.from('attachments').delete().eq('id', attachmentId);

      // Delete associations
      await _supabase
          .from('form_attachments')
          .delete()
          .eq('attachment_id', attachmentId);
    } catch (e) {
      AppLogger.error('Error deleting attachment', error: e);
      rethrow;
    }
  }

  /// Download attachment with verification
  Future<File> downloadAttachmentWithVerification({
    required String attachmentId,
    required String expectedHash,
  }) async {
    try {
      // Get attachment info
      final attachmentData = await _supabase
          .from('attachments')
          .select()
          .eq('id', attachmentId)
          .single();

      // Download file
      final fileName = attachmentData['file_name'] as String;
      final storagePath = 'form-attachments/$attachmentId';

      final fileData =
          await _supabase.storage.from(uploadsBucket).download(storagePath);

      // Verify hash
      final downloadHash = sha256.convert(fileData).toString();
      if (downloadHash != expectedHash) {
        throw Exception('Downloaded file hash mismatch');
      }

      // Save to temp file
      final tempFile = File('/tmp/$fileName');
      await tempFile.writeAsBytes(fileData);

      return tempFile;
    } catch (e) {
      AppLogger.error('Error downloading attachment', error: e);
      rethrow;
    }
  }

  /// Get upload progress (for resuming)
  Future<UploadProgress?> getUploadProgress(String sessionId) async {
    return await _getUploadProgress(sessionId);
  }

  /// Link attachment to form
  Future<void> linkAttachmentToForm({
    required String attachmentId,
    required String formId,
    required String fieldName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabase.from('form_attachments').insert({
        'attachment_id': attachmentId,
        'form_id': formId,
        'field_name': fieldName,
        'metadata': jsonEncode(metadata ?? {}),
        'linked_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('Error linking attachment', error: e);
      rethrow;
    }
  }

  /// Upload file with chunking & verification (resumable)
  Future<UploadResult> uploadFileWithChunking({
    required File file,
    required String formId,
    required String fieldName,
    String? uploadSessionId,
  }) async {
    // Validate file
    if (!file.existsSync()) {
      throw Exception('File not found');
    }

    final fileSize = await file.length();
    if (fileSize > maxFileSize) {
      throw Exception('File exceeds maximum size of 500MB');
    }

    // Generate session ID for resumable upload
    final sessionId = uploadSessionId ?? const Uuid().v4();

    // Calculate file hash for integrity
    final fileHash = await _calculateFileHash(file);

    // Get existing progress (if resuming)
    final existingProgress = await _getUploadProgress(sessionId);
    final startChunk = existingProgress?.uploadedChunks.length ?? 0;

    final totalChunks = (fileSize / chunkSize).ceil();
    final uploadedChunks = <int>[];

    try {
      // Upload chunks
      for (int i = startChunk; i < totalChunks; i++) {
        final start = i * chunkSize;
        final end = min(start + chunkSize, fileSize);
        // final currentChunkSize = end - start;

        final chunk = await file.openRead(start, end).toList();
        final chunkBytes = chunk.fold<List<int>>([], (p, e) => [...p, ...e]);
        final chunkHash = sha256.convert(chunkBytes).toString();

        // Upload chunk with verification info
        await _uploadChunk(
          sessionId: sessionId,
          chunkIndex: i,
          totalChunks: totalChunks,
          chunkData: chunkBytes,
          chunkHash: chunkHash,
          formId: formId,
          fieldName: fieldName,
        );

        uploadedChunks.add(i);

        // Save progress for resumability
        await _saveUploadProgress(
          sessionId: sessionId,
          formId: formId,
          fieldName: fieldName,
          totalChunks: totalChunks,
          uploadedChunks: uploadedChunks,
          fileHash: fileHash,
          fileName: file.path.split('/').last,
        );
      }

      // Verify complete upload
      await _verifyUpload(
        sessionId: sessionId,
        expectedHash: fileHash,
        totalChunks: totalChunks,
      );

      // Assemble chunks on server
      final assemblyResult = await _assembleChunks(
        sessionId: sessionId,
        formId: formId,
        fieldName: fieldName,
        fileHash: fileHash,
        totalChunks: totalChunks,
      );

      // Clean up progress
      await _clearUploadProgress(sessionId);

      return assemblyResult;
    } catch (e) {
      // Save progress for retry
      await _saveUploadProgress(
        sessionId: sessionId,
        formId: formId,
        fieldName: fieldName,
        totalChunks: totalChunks,
        uploadedChunks: uploadedChunks,
        fileHash: fileHash,
        fileName: file.path.split('/').last,
      );
      rethrow;
    }
  }

  /// Verify attachment integrity
  Future<bool> verifyAttachment({
    required String attachmentId,
    required String expectedHash,
  }) async {
    try {
      final result = await _supabase.rpc(
        'verify_attachment_hash',
        params: {
          'attachment_id': attachmentId,
          'expected_hash': expectedHash,
        },
      );
      return result as bool;
    } catch (e) {
      AppLogger.warning('Error verifying attachment', error: e);
      return false;
    }
  }

  Future<UploadResult> _assembleChunks({
    required String sessionId,
    required String formId,
    required String fieldName,
    required String fileHash,
    required int totalChunks,
  }) async {
    try {
      final result = await _supabase.rpc('assemble_upload_chunks', params: {
        'session_id': sessionId,
        'form_id': formId,
        'field_name': fieldName,
        'file_hash': fileHash,
        'total_chunks': totalChunks,
      });

      final resultData = result as Map<String, dynamic>;

      return UploadResult(
        attachmentId: resultData['attachment_id'] as String,
        fileName: resultData['file_name'] as String,
        fileSize: resultData['file_size'] as int,
        fileHash: fileHash,
        uploadSessionId: sessionId,
        uploadedAt: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('Error assembling chunks', error: e);
      rethrow;
    }
  }

  // Private helper methods

  Future<String> _calculateFileHash(File file) async {
    // Read file and calculate SHA256 hash
    final fileBytes = await file.readAsBytes();
    return sha256.convert(fileBytes).toString();
  }

  Future<void> _clearUploadProgress(String sessionId) async {
    try {
      await _supabase.from('upload_sessions').delete().eq(
            'session_id',
            sessionId,
          );
    } catch (e) {
      AppLogger.warning('Error clearing upload progress', error: e);
    }
  }

  Future<UploadProgress?> _getUploadProgress(String sessionId) async {
    try {
      final response = await _supabase
          .from('upload_sessions')
          .select()
          .eq('session_id', sessionId)
          .maybeSingle();

      if (response == null) return null;

      final uploadedChunks = List<int>.from(
        jsonDecode(response['uploaded_chunks'] as String? ?? '[]') as List,
      );

      return UploadProgress(
        sessionId: sessionId,
        formId: response['form_id'] as String,
        fieldName: response['field_name'] as String,
        totalChunks: response['total_chunks'] as int,
        uploadedChunks: uploadedChunks,
        fileHash: response['file_hash'] as String,
        fileName: response['file_name'] as String,
        startedAt: DateTime.parse(response['started_at'] as String),
      );
    } catch (e) {
      AppLogger.warning('Error getting upload progress', error: e);
      return null;
    }
  }

  Future<void> _saveUploadProgress({
    required String sessionId,
    required String formId,
    required String fieldName,
    required int totalChunks,
    required List<int> uploadedChunks,
    required String fileHash,
    required String fileName,
  }) async {
    try {
      await _supabase.from('upload_sessions').upsert({
        'session_id': sessionId,
        'form_id': formId,
        'field_name': fieldName,
        'total_chunks': totalChunks,
        'uploaded_chunks': jsonEncode(uploadedChunks),
        'file_hash': fileHash,
        'file_name': fileName,
        'started_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.warning('Error saving upload progress', error: e);
    }
  }

  Future<void> _uploadChunk({
    required String sessionId,
    required int chunkIndex,
    required int totalChunks,
    required List<int> chunkData,
    required String chunkHash,
    required String formId,
    required String fieldName,
  }) async {
    try {
      final uploadPath = 'uploads/$sessionId/chunk_$chunkIndex';

      await _supabase.storage.from(uploadsBucket).uploadBinary(
            uploadPath,
            Uint8List.fromList(chunkData),
            fileOptions:
                const FileOptions(contentType: 'application/octet-stream'),
          );

      // Record chunk metadata for verification
      await _supabase.from('upload_chunks').insert({
        'session_id': sessionId,
        'chunk_index': chunkIndex,
        'total_chunks': totalChunks,
        'chunk_hash': chunkHash,
        'chunk_size': chunkData.length,
        'uploaded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('Error uploading chunk $chunkIndex', error: e);
      rethrow;
    }
  }

  Future<void> _verifyUpload({
    required String sessionId,
    required String expectedHash,
    required int totalChunks,
  }) async {
    try {
      final result = await _supabase.rpc('verify_upload_chunks', params: {
        'session_id': sessionId,
        'total_chunks': totalChunks,
      });

      if (!(result as bool)) {
        throw Exception('Upload verification failed');
      }
    } catch (e) {
      AppLogger.error('Error verifying upload', error: e);
      rethrow;
    }
  }
}

/// Represents an attachment linked to a form.
class FormAttachment {
  /// The unique identifier for the attachment.
  final String attachmentId;

  /// The unique identifier for the form.
  final String formId;

  /// The name of the field the attachment is linked to.
  final String fieldName;

  /// The name of the file.
  final String fileName;

  /// The size of the file in bytes.
  final int fileSize;

  /// The SHA256 hash of the file.
  final String fileHash;

  /// Additional metadata for the attachment.
  final Map<String, dynamic> metadata;

  /// The date and time the attachment was linked to the form.
  final DateTime linkedAt;

  /// Creates a [FormAttachment] instance.
  FormAttachment({
    required this.attachmentId,
    required this.formId,
    required this.fieldName,
    required this.fileName,
    required this.fileSize,
    required this.fileHash,
    required this.metadata,
    required this.linkedAt,
  });

  /// Creates a [FormAttachment] from a JSON map.
  factory FormAttachment.fromJson(Map<String, dynamic> json) {
    final attachmentData = json['attachments'] as Map<String, dynamic>? ?? {};

    return FormAttachment(
      attachmentId: json['attachment_id'] as String,
      formId: json['form_id'] as String,
      fieldName: json['field_name'] as String,
      fileName: attachmentData['file_name'] as String? ?? 'unknown',
      fileSize: (attachmentData['file_size'] as num? ?? 0).toInt(),
      fileHash: attachmentData['file_hash'] as String? ?? '',
      metadata: jsonDecode(json['metadata'] as String? ?? '{}')
          as Map<String, dynamic>,
      linkedAt: DateTime.parse(json['linked_at'] as String),
    );
  }
}

/// Form Attachment Tracker - Manages attachments per form
class FormAttachmentTracker {
  final SupabaseClient _supabase;

  /// The unique identifier of the form being tracked.
  final String formId;

  /// Creates a [FormAttachmentTracker] instance for a specific form.
  FormAttachmentTracker({
    required this.formId,
    required SupabaseClient supabase,
  }) : _supabase = supabase;

  /// Get attachments for specific field
  Future<List<FormAttachment>> getFieldAttachments(String fieldName) async {
    try {
      final response = await _supabase
          .from('form_attachments')
          .select('*, attachments(*)')
          .eq('form_id', formId)
          .eq('field_name', fieldName);

      return (response as List)
          .map((item) => FormAttachment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.warning('Error getting field attachments', error: e);
      return [];
    }
  }

  /// Get all attachments for form
  Future<List<FormAttachment>> getFormAttachments() async {
    try {
      final response = await _supabase
          .from('form_attachments')
          .select('*, attachments(*)')
          .eq('form_id', formId);

      return (response as List)
          .map((item) => FormAttachment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.warning('Error getting form attachments', error: e);
      return [];
    }
  }

  /// Remove attachment from form
  Future<void> removeAttachment(String attachmentId) async {
    try {
      await _supabase
          .from('form_attachments')
          .delete()
          .eq('attachment_id', attachmentId)
          .eq('form_id', formId);
    } catch (e) {
      AppLogger.error('Error removing attachment', error: e);
      rethrow;
    }
  }
}

/// Represents the progress of a file upload.
class UploadProgress {
  /// The unique identifier for the upload session.
  final String sessionId;

  /// The unique identifier for the form.
  final String formId;

  /// The name of the field the attachment is linked to.
  final String fieldName;

  /// The total number of chunks to be uploaded.
  final int totalChunks;

  /// The list of chunk indices that have been uploaded.
  /// The list of chunks that have been successfully uploaded.
  /// A list of indices of chunks that have been successfully uploaded.
  final List<int> uploadedChunks;

  /// The SHA256 hash of the file.
  final String fileHash;

  /// The name of the file.
  final String fileName;

  /// The date and time the upload started.
  final DateTime startedAt;

  /// Creates an [UploadProgress] instance.
  UploadProgress({
    required this.sessionId,
    required this.formId,
    required this.fieldName,
    required this.totalChunks,
    required this.uploadedChunks,
    required this.fileHash,
    required this.fileName,
    required this.startedAt,
  });

  /// Whether all chunks in the file have been successfully uploaded.
  bool get isComplete => uploadedChunks.length == totalChunks;

  /// The percentage of chunks that have been successfully uploaded.
  double get progressPercentage => (uploadedChunks.length / totalChunks) * 100;
}

/// Data Models for Attachments

/// Represents the result of a file upload.
class UploadResult {
  /// The unique identifier for the attachment.
  final String attachmentId;

  /// The name of the uploaded file.
  final String fileName;

  /// The size of the uploaded file in bytes.
  final int fileSize;

  /// The SHA256 hash of the uploaded file.
  final String fileHash;

  /// The unique identifier for the upload session.
  final String uploadSessionId;

  /// The date and time the upload was completed.
  final DateTime uploadedAt;

  /// Creates an [UploadResult] instance.
  UploadResult({
    required this.attachmentId,
    required this.fileName,
    required this.fileSize,
    required this.fileHash,
    required this.uploadSessionId,
    required this.uploadedAt,
  });
}

// SQL Schema for Phase 5

/*
CREATE TABLE IF NOT EXISTS public.attachments (
  id TEXT PRIMARY KEY,
  file_name TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  file_hash TEXT NOT NULL,
  mime_type TEXT,
  uploaded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.form_attachments (
  id BIGSERIAL PRIMARY KEY,
  attachment_id TEXT REFERENCES public.attachments(id) ON DELETE CASCADE,
  form_id TEXT NOT NULL,
  field_name TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  linked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.upload_chunks (
  id BIGSERIAL PRIMARY KEY,
  session_id TEXT NOT NULL,
  chunk_index INTEGER NOT NULL,
  total_chunks INTEGER NOT NULL,
  chunk_hash TEXT NOT NULL,
  chunk_size BIGINT NOT NULL,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(session_id, chunk_index)
);

CREATE TABLE IF NOT EXISTS public.upload_sessions (
  session_id TEXT PRIMARY KEY,
  form_id TEXT NOT NULL,
  field_name TEXT NOT NULL,
  total_chunks INTEGER NOT NULL,
  uploaded_chunks JSONB DEFAULT '[]',
  file_hash TEXT NOT NULL,
  file_name TEXT NOT NULL,
  started_at TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_form_attachments_form_id ON public.form_attachments(form_id);
CREATE INDEX idx_form_attachments_field_name ON public.form_attachments(field_name);
CREATE INDEX idx_upload_chunks_session_id ON public.upload_chunks(session_id);
CREATE INDEX idx_attachments_file_hash ON public.attachments(file_hash);
*/
