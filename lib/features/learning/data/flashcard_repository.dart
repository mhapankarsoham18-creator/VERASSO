import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import 'flashcard_model.dart';

/// Repository for managing flashcard decks and individual cards.
class FlashcardRepository {
  final SupabaseClient _client;

  /// Creates a [FlashcardRepository] instance.
  FlashcardRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Adds a new card to a flashcard deck.
  Future<void> addCard(Flashcard card) async {
    await _client.from('flashcards').insert(card.toJson());
  }

  /// Creates a new flashcard deck.
  Future<void> createDeck(Deck deck) async {
    await _client.from('decks').insert(deck.toJson());
  }

  /// Deletes a specific deck and all its associated cards.
  Future<void> deleteDeck(String deckId) async {
    await _client.from('decks').delete().eq('id', deckId);
  }

  /// Retrieves all cards within a specific deck.
  Future<List<Flashcard>> getCards(String deckId) async {
    try {
      final response = await _client
          .from('flashcards')
          .select()
          .eq('deck_id', deckId)
          .order('created_at', ascending: true);
      return (response as List).map((e) => Flashcard.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Retrieves all flashcard decks.
  Future<List<Deck>> getDecks() async {
    try {
      final response = await _client
          .from('decks')
          .select()
          .order('created_at', ascending: false);
      return (response as List).map((e) => Deck.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
