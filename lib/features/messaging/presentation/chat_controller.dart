import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/messaging/data/message_repository.dart';

/// Provider for the [ChatController] instance.
final chatControllerProvider =
    StateNotifierProvider<ChatController, AsyncValue<void>>((ref) {
  return ChatController(ref.watch(messageRepositoryProvider), ref);
});

// Since decryption is async, we might need a FutureProvider for each message content
// OR simpler: we fetch messages and decode them in the UI logic or a transform stream.
// Transforming the stream to decrypt on the fly is elegant but heavy.
// Let's rely on the UI fetching decryption to avoid blocking logic.

/// Controller for managing chat message interactions and state.
class ChatController extends StateNotifier<AsyncValue<void>> {
  final MessageRepository _repo;
  final Ref _ref;

  /// Creates a [ChatController] instance and initializes keys.
  ChatController(this._repo, this._ref) : super(const AsyncData(null)) {
    _repo.initialize(); // Ensure keys exist
  }

  /// Sends a message to a recipient and updates the state.
  Future<void> sendMessage(String receiverId, String content,
      {String mediaType = 'text'}) async {
    state = const AsyncLoading();
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = const AsyncError('User not logged in', StackTrace.empty);
      return;
    }

    state = await AsyncValue.guard(() => _repo.sendMessage(
        senderId: user.id,
        receiverId: receiverId,
        content: content,
        mediaType: mediaType));
  }
}
