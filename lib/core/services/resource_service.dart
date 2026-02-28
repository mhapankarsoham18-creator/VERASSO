import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:verasso/core/monitoring/app_logger.dart';

/// Provider for the [ResourceService] instance.
final resourceServiceProvider = Provider((ref) => ResourceService());

/// Service that manages on-demand loading of large application assets (3D models, textures).
class ResourceService {
  final Map<String, double> _downloadProgress = {};
  final Set<String> _cachedResources = {};

  final _http = http.Client();

  /// Initiates a real download of a large asset.
  Future<void> ensureResource(String resourceId, {String? url}) async {
    if (_cachedResources.contains(resourceId)) return;

    final downloadUrl = url ?? 'https://api.verasso.io/v1/assets/$resourceId';
    AppLogger.info(
        'ResourceService: Starting download for $resourceId from $downloadUrl');

    try {
      _downloadProgress[resourceId] = 0.0;

      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response =
          await _http.send(request).timeout(const Duration(minutes: 5));

      if (response.statusCode != 200) {
        throw Exception('Failed to download resource: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      int downloaded = 0;

      await for (var chunk in response.stream) {
        downloaded += chunk.length;
        if (contentLength > 0) {
          _downloadProgress[resourceId] = downloaded / contentLength;
        }
        // Throttle log or UI update if needed
      }

      _cachedResources.add(resourceId);
      AppLogger.info('ResourceService: $resourceId ready');
    } catch (e) {
      AppLogger.error('ResourceService: Download failed for $resourceId',
          error: e);
      rethrow;
    } finally {
      _downloadProgress.remove(resourceId);
    }
  }

  /// Gets the download progress of a resource (0.0 to 1.0).
  double getProgress(String resourceId) => _downloadProgress[resourceId] ?? 0.0;

  /// Checks if a resource is available locally.
  bool isResourceAvailable(String resourceId) =>
      _cachedResources.contains(resourceId);
}
