// Form and Attachment Handling with Verification and Chunked Uploads
// Supports crash-safe file uploads, verification, and metadata tracking

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Represents metadata for an attachment.
class AttachmentMetadata {
  /// The unique identifier for the attachment.
  final String id;

  /// The name of the file.
  final String fileName;

  /// The size of the file in bytes.
  final int fileSize;

  /// The MIME type of the file.
  final String mimeType;

  /// The SHA256 hash of the file.
  final String sha256;

  /// The unique identifier for the user who uploaded the file.
  final String uploadedBy;

  /// The date and time the file was uploaded.
  final DateTime uploadedAt;

  /// The unique identifier for the entity the attachment is linked to.
  final String entityId;

  /// The type of the entity the attachment is linked to.
  final String entityType;

  /// The storage URL for the attachment.
  final String storageUrl;

  /// The number of chunks the file was divided into for upload.
  final int chunkCount;

  /// Whether the attachment has been verified.
  final bool verified;

  /// Creates an [AttachmentMetadata] instance.
  AttachmentMetadata({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.sha256,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.entityId,
    required this.entityType,
    required this.storageUrl,
    required this.chunkCount,
    required this.verified,
  });

  /// Creates an [AttachmentMetadata] from a JSON map.
  /// Creates an [AttachmentMetadata] from a JSON map.
  factory AttachmentMetadata.fromJson(Map<String, dynamic> json) =>
      AttachmentMetadata(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        fileSize: json['fileSize'] as int,
        mimeType: json['mimeType'] as String,
        sha256: json['sha256'] as String,
        uploadedBy: json['uploadedBy'] as String,
        uploadedAt: DateTime.parse(json['uploadedAt'] as String),
        entityId: json['entityId'] as String,
        entityType: json['entityType'] as String,
        storageUrl: json['storageUrl'] as String,
        chunkCount: json['chunk_count'] as int,
        verified: json['verified'] as bool? ?? true,
      );

  /// Converts the [AttachmentMetadata] to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'fileSize': fileSize,
        'mimeType': mimeType,
        'sha256': sha256,
        'uploadedBy': uploadedBy,
        'uploadedAt': uploadedAt.toIso8601String(),
        'entityId': entityId,
        'entityType': entityType,
        'storageUrl': storageUrl,
        'chunk_count': chunkCount,
        'verified': verified,
      };
}

/// Service for handling file attachments and chunked uploads.
class AttachmentService {
  /// The size of each file chunk for upload.
  static const int chunkSize = 5 * 1024 * 1024; // 5MB chunks
  /// The name of the storage bucket for attachments.
  static const String storageBucket = 'attachments';

  /// The Supabase client used for operations.
  final SupabaseClient _supabase;

  /// Creates an [AttachmentService] instance.
  AttachmentService(this._supabase);

  /// Download chunked file from storage
  Future<File> downloadFile(
    String attachmentId,
    String fileName, {
    void Function(double)? onProgress,
  }) async {
    try {
      final attachment = await _supabase
          .from('attachments')
          .select()
          .eq('id', attachmentId)
          .single();

      final chunkCount = attachment['chunk_count'] as int;
      final outputFile = File('${Directory.systemTemp.path}/$fileName');
      final sink = outputFile.openWrite();
      int downloadedBytes = 0;
      final totalBytes = attachment['file_size'] as int;

      // Download chunks sequentially
      for (int i = 0; i < chunkCount; i++) {
        final chunkData = await _supabase.storage
            .from(storageBucket)
            .download('$attachmentId/chunk_$i');

        sink.add(chunkData);
        downloadedBytes += chunkData.length;
        onProgress?.call(downloadedBytes / totalBytes);
      }

      await sink.flush();
      await sink.close();

      return outputFile;
    } catch (e) {
      AppLogger.error('Error downloading file', error: e);
      rethrow;
    }
  }

  /// Upload file with chunking and verification.
  ///
  /// Returns [AttachmentMetadata] on success.
  Future<AttachmentMetadata> uploadFile({
    required File file,
    required String entityId,
    required String entityType,
    void Function(double)? onProgress,
  }) async {
    try {
      // Verify file before upload
      final verification = await _verifyFile(file);
      if (!verification.isValid) {
        throw 'File verification failed: ${verification.errors.join(', ')}';
      }

      // Prepare upload metadata
      final fileName = file.path.split('/').last;
      final fileSize = file.lengthSync();
      final uploadSession = UploadSession(
        id: '${entityId}_${DateTime.now().millisecondsSinceEpoch}',
        fileName: fileName,
        fileSize: fileSize,
        uploadedBytes: 0,
        chunks: [],
      );

      // Upload in chunks
      int uploadedBytes = 0;
      int chunkIndex = 0;

      while (uploadedBytes < fileSize) {
        final chunkStart = uploadedBytes;
        final chunkEnd = (uploadedBytes + chunkSize).clamp(0, fileSize);
        final chunkData = file.readAsBytesSync().sublist(chunkStart, chunkEnd);

        // Upload chunk
        final chunkHash = sha256.convert(chunkData).toString();
        final chunkPath = '${uploadSession.id}/chunk_$chunkIndex';

        await _supabase.storage.from(storageBucket).uploadBinary(
              chunkPath,
              chunkData,
              fileOptions:
                  const FileOptions(cacheControl: '3600', upsert: true),
            );

        uploadSession.chunks.add(ChunkInfo(
          index: chunkIndex,
          size: chunkData.length,
          hash: chunkHash,
          uploadedAt: DateTime.now(),
        ));

        uploadedBytes = chunkEnd;
        chunkIndex++;

        // Report progress
        final progress = uploadedBytes / fileSize;
        onProgress?.call(progress);
      }

      // Verify all chunks uploaded
      if (!await _verifyChunks(uploadSession)) {
        throw 'Chunk verification failed';
      }

      // Create final attachment metadata
      final attachmentMetadata = AttachmentMetadata(
        id: uploadSession.id,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: _getMimeType(fileName),
        sha256: sha256.convert(file.readAsBytesSync()).toString(),
        uploadedBy: _supabase.auth.currentUser?.id ?? '',
        uploadedAt: DateTime.now(),
        entityId: entityId,
        entityType: entityType,
        storageUrl: _supabase.storage
            .from(storageBucket)
            .getPublicUrl(uploadSession.id),
        chunkCount: uploadSession.chunks.length,
        verified: true,
      );

      // Save metadata to database
      await _supabase.from('attachments').insert(attachmentMetadata.toJson());

      return attachmentMetadata;
    } catch (e) {
      AppLogger.error('Error uploading file', error: e);
      rethrow;
    }
  }

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    const mimeTypes = {
      'pdf': 'application/pdf',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
      'gif': 'image/gif',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'm4a': 'audio/mp4',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'txt': 'text/plain',
      'csv': 'text/csv',
      'json': 'application/json',
      'zip': 'application/zip',
    };

    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  /// Verify all chunks were uploaded correctly
  Future<bool> _verifyChunks(UploadSession session) async {
    for (final chunk in session.chunks) {
      try {
        final response = await _supabase.storage
            .from(storageBucket)
            .download('${session.id}/chunk_${chunk.index}');

        final downloadHash = sha256.convert(response).toString();
        if (downloadHash != chunk.hash) {
          return false;
        }
      } catch (e) {
        return false;
      }
    }
    return true;
  }

  /// Verify file before upload
  Future<FileVerification> _verifyFile(File file) async {
    final errors = <String>[];

    // Check file exists
    if (!file.existsSync()) {
      errors.add('File does not exist');
    }

    // Check file size (max 100MB)
    final fileSize = file.lengthSync();
    if (fileSize > 100 * 1024 * 1024) {
      errors.add('File exceeds 100MB limit');
    }

    if (fileSize == 0) {
      errors.add('File is empty');
    }

    // Check MIME type
    final fileName = file.path.split('/').last;
    final mimeType = _getMimeType(fileName);

    const allowedMimeTypes = [
      'application/pdf',
      'image/jpeg',
      'image/png',
      'image/webp',
      'video/mp4',
      'video/quicktime',
      'audio/mpeg',
      'audio/wav',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ];

    if (!allowedMimeTypes.contains(mimeType)) {
      errors.add('File type not allowed: $mimeType');
    }

    // Optional: Scan for viruses using VirusTotal API
    // This would require API key and should be done on backend

    return FileVerification(
      isValid: errors.isEmpty,
      errors: errors,
      mimeType: mimeType,
    );
  }
}

/// Metadata for a single chunk of an uploaded file.
class ChunkInfo {
  /// The index of the chunk in the file.
  final int index;

  /// The size of the chunk in bytes.
  final int size;

  /// The SHA256 hash of the chunk data.
  final String hash;

  /// The date and time the chunk was uploaded.
  final DateTime uploadedAt;

  /// Creates a [ChunkInfo] instance.
  ChunkInfo({
    required this.index,
    required this.size,
    required this.hash,
    required this.uploadedAt,
  });
}

/// Represents the result of a file verification check.
class FileVerification {
  /// Whether the file is valid.
  final bool isValid;

  /// A list of errors found during verification.
  final List<String> errors;

  /// The detected MIME type of the file.
  final String mimeType;

  /// Creates a [FileVerification] instance.
  FileVerification({
    required this.isValid,
    required this.errors,
    required this.mimeType,
  });
}

/// Represents the data submitted in a form.
class FormData {
  /// The unique identifier for the form.
  final String formId;

  /// The unique identifier for the user who submitted the form.
  final String userId;

  /// A map of field names to their values.
  final Map<String, FormFieldValue> fields;

  /// A list of attachments associated with the form.
  final List<AttachmentMetadata> attachments;

  /// The date and time the form was created.
  final DateTime createdAt;

  /// The date and time the form was submitted, or null if it's a draft.
  final DateTime? submittedAt;

  /// The status of the form (e.g., 'draft', 'submitted', 'archived').
  final String status; // 'draft', 'submitted', 'archived'

  /// Creates a [FormData] instance.
  FormData({
    required this.formId,
    required this.userId,
    required this.fields,
    required this.attachments,
    required this.createdAt,
    this.submittedAt,
    this.status = 'draft',
  });

  /// Creates a [FormData] from a JSON map.
  factory FormData.fromJson(Map<String, dynamic> json) => FormData(
        formId: json['formId'] as String,
        userId: json['userId'] as String,
        fields: (json['fields'] as Map).map(
          (k, v) => MapEntry(
              k,
              FormFieldValue(
                fieldId: k as String,
                fieldName: v['fieldName'] as String,
                fieldType: v['fieldType'] as String,
                value: v['value'],
                required: v['required'] as bool,
                validationErrors:
                    List<String>.from(v['validationErrors'] as List? ?? []),
                capturedAt: v['capturedAt'] != null
                    ? DateTime.parse(v['capturedAt'] as String)
                    : null,
              )),
        ),
        attachments: (json['attachments'] as List?)
                ?.map((a) => AttachmentMetadata.fromJson(a))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt'] as String),
        submittedAt: json['submittedAt'] != null
            ? DateTime.parse(json['submittedAt'] as String)
            : null,
        status: json['status'] as String? ?? 'draft',
      );

  /// Whether all fields in the form are valid.
  bool get isValid => fields.values.every((field) => field.isValid);

  /// Converts the [FormData] to a JSON map.
  Map<String, dynamic> toJson() => {
        'formId': formId,
        'userId': userId,
        'fields': fields.map((k, v) => MapEntry(k, v.toJson())),
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'submittedAt': submittedAt?.toIso8601String(),
        'status': status,
      };
}

/// Represents a field value in a form.
class FormFieldValue {
  /// The unique identifier for the field.
  final String fieldId;

  /// The name of the field.
  final String fieldName;

  /// The type of the field.
  final String
      fieldType; // 'text', 'email', 'number', 'select', 'checkbox', 'date', 'attachment'

  /// The current value of the field.
  final dynamic value;

  /// Whether the field is required.
  final bool required;

  /// A list of validation errors for the field, if any.
  final List<String>? validationErrors;

  /// The date and time the field value was captured.
  final DateTime? capturedAt;

  /// Creates a [FormFieldValue] instance.
  FormFieldValue({
    required this.fieldId,
    required this.fieldName,
    required this.fieldType,
    required this.value,
    required this.required,
    this.validationErrors,
    this.capturedAt,
  });

  /// Whether the field value is considered valid.
  bool get isValid =>
      (validationErrors?.isEmpty ?? true) &&
      (!required || (value != null && value.toString().isNotEmpty));

  /// Converts the [FormFieldValue] to a JSON map.
  Map<String, dynamic> toJson() => {
        'fieldId': fieldId,
        'fieldName': fieldName,
        'fieldType': fieldType,
        'value': value,
        'required': required,
        'validationErrors': validationErrors,
        'capturedAt': capturedAt?.toIso8601String(),
      };
}

/// Represents an ongoing file upload session.
class UploadSession {
  /// The unique identifier for the session.
  final String id;

  /// The name of the file being uploaded.
  final String fileName;

  /// The total size of the file in bytes.
  final int fileSize;

  /// The number of bytes that have been uploaded so far.
  int uploadedBytes;

  /// The list of chunks that make up the file.
  final List<ChunkInfo> chunks;

  /// Creates an [UploadSession] instance.
  UploadSession({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.uploadedBytes,
    required this.chunks,
  });
}
