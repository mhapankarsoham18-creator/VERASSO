import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../auth/presentation/auth_controller.dart';
import '../../data/flashcard_model.dart';
import '../../data/flashcard_repository.dart';

/// Future provider for fetching cards within a specific deck.
final deckCardsProvider =
    FutureProvider.family<List<Flashcard>, String>((ref, deckId) async {
  final repo = ref.watch(flashcardRepositoryProvider);
  return repo.getCards(deckId);
});

/// Future provider for fetching all flashcard decks.
final decksProvider = FutureProvider((ref) async {
  final repo = ref.watch(flashcardRepositoryProvider);
  return repo.getDecks();
});

/// Provider for the [FlashcardController] instance.
final flashcardControllerProvider =
    StateNotifierProvider<FlashcardController, AsyncValue<void>>((ref) {
  return FlashcardController(ref.watch(flashcardRepositoryProvider), ref);
});

/// Provider for the [FlashcardRepository] instance.
final flashcardRepositoryProvider = Provider((ref) => FlashcardRepository());

/// Controller for managing flashcard deck creation and card management.
class FlashcardController extends StateNotifier<AsyncValue<void>> {
  final FlashcardRepository _repo;
  final Ref _ref;

  /// Creates a [FlashcardController] instance.
  FlashcardController(this._repo, this._ref) : super(const AsyncData(null));

  /// Adds a new flashcard to a specific deck.
  Future<void> addCard(String deckId, String front, String back) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.addCard(
          Flashcard(id: '', deckId: deckId, frontText: front, backText: back));
      _ref.invalidate(deckCardsProvider(deckId));
    });
  }

  /// Creates a new flashcard deck for the current user.
  Future<void> createDeck(
      String title, String subject, String description) async {
    state = const AsyncLoading();
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = await AsyncValue.guard(() async {
      await _repo.createDeck(Deck(
          id: '',
          userId: user.id,
          title: title,
          subject: subject,
          description: description,
          createdAt: DateTime.now()));
      _ref.invalidate(decksProvider);
    });
  }
}
