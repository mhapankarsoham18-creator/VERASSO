import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/services/bluetooth_mesh_service.dart';
import 'package:verasso/core/services/offline_storage_service.dart';

import '../../../core/mesh/models/mesh_packet.dart';
import '../domain/news_model.dart';

/// Provider for the [MeshNewsService] instance.
final meshNewsServiceProvider =
    StateNotifierProvider<MeshNewsService, List<NewsArticle>>((ref) {
  final meshService = ref.watch(bluetoothMeshServiceProvider);
  final storage = ref.watch(offlineStorageServiceProvider);
  return MeshNewsService(meshService, storage);
});

/// Service that manages news propagation and reception over the P2P Bluetooth mesh network.
class MeshNewsService extends StateNotifier<List<NewsArticle>> {
  final BluetoothMeshService _meshService;
  final OfflineStorageService _storage;
  StreamSubscription? _meshSub;

  /// Creates a [MeshNewsService] and initializes mesh listeners.
  MeshNewsService(this._meshService, this._storage) : super([]) {
    _init();
  }

  /// Broadcasts a news article to the mesh network.
  ///
  /// [article] is the [NewsArticle] to be broadcasted.
  /// The article is also saved to the local state if it's new.
  Future<void> broadcastArticle(NewsArticle article) async {
    await _meshService.broadcastPacket(
      MeshPayloadType.feedPost,
      article.toJson(),
    );
    AppLogger.info('Broadcasting article over mesh: ${article.title}');

    // Deduplicate and save to state if it's new
    if (!state.any((a) => a.id == article.id)) {
      state = [article, ...state];
      _saveState();
    }
  }

  @override
  void dispose() {
    _meshSub?.cancel();
    super.dispose();
  }

  void _broadcastNewsSummary() {
    if (state.isEmpty) return;

    // Send just the IDs/Titles/FeaturedStatus to neighbors so they can request full content if missing
    final summary = state
        .map((a) => {
              'id': a.id,
              'title': a.title,
              'is_featured': a.isFeatured,
            })
        .toList();
    _meshService.broadcastPacket(
      MeshPayloadType.meshSummary,
      {'news_summary': summary},
      priority: MeshPriority.low,
    );
  }

  void _handleIncomingArticle(MeshPacket packet) {
    try {
      final article = NewsArticle.fromJson(packet.payload);

      // Deduplicate
      if (state.any((a) => a.id == article.id)) return;

      // Check for Verified Source
      const officialPrefix = "VERASSO_OFFICIAL_";
      bool isVerifiedSource = packet.publicKey != null &&
          packet.publicKey!.startsWith(officialPrefix);

      final updatedArticle = article.copyWith(
        isFeatured: isVerifiedSource || article.isFeatured,
        authorName: isVerifiedSource ? "Verasso Official" : article.authorName,
      );

      state = [updatedArticle, ...state];
      _saveState();

      AppLogger.info(
          'Received P2P News Article: ${article.title} (Verified: $isVerifiedSource)');
    } catch (e) {
      AppLogger.error('Failed to parse mesh article', error: e);
    }
  }

  void _handleMeshSummary(Map<String, dynamic> payload) {
    final summary = payload['news_summary'] as List?;
    if (summary == null) return;

    final myIds = state.map((a) => a.id).toSet();
    final missingIds = summary
        .where((item) => !myIds.contains(item['id']))
        .map((item) => item['id'] as String)
        .toList();

    if (missingIds.isNotEmpty) {
      AppLogger.info(
          'Requesting ${missingIds.length} missing articles from mesh');
      _meshService.broadcastPacket(
        MeshPayloadType.packetRequest,
        {'article_ids': missingIds},
        priority: MeshPriority.low,
      );
    }
  }

  void _handlePacketRequest(Map<String, dynamic> payload) {
    final requestedIds = payload['article_ids'] as List?;
    if (requestedIds == null) return;

    for (var id in requestedIds) {
      try {
        final article = state.firstWhere((a) => a.id == id);
        broadcastArticle(article);
      } catch (_) {
        // Article not found locally
      }
    }
  }

  void _init() {
    // Load from cache first
    final cached = _storage.getCachedData('mesh_news_articles');
    if (cached != null && cached is List) {
      state = cached.map((json) => NewsArticle.fromJson(json)).toList();
    }

    // Listen to mesh messages
    _meshSub = _meshService.meshStream.listen((packet) {
      switch (packet.type) {
        case MeshPayloadType.feedPost:
          _handleIncomingArticle(packet);
          break;
        case MeshPayloadType.meshSummary:
          _handleMeshSummary(packet.payload);
          break;
        case MeshPayloadType.packetRequest:
          _handlePacketRequest(packet.payload);
          break;
        default:
          break;
      }
    });

    // Periodically broadcast a "News Summary" (Gossip)
    _broadcastNewsSummary();
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _broadcastNewsSummary();
    });
  }

  void _saveState() {
    _storage.cacheData(
        'mesh_news_articles', state.map((a) => a.toJson()).toList());
  }
}
