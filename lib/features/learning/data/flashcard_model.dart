/// Represents a collection or deck of flashcards for study.
class Deck {
  /// Unique identifier of the deck.
  final String id;

  /// The ID of the student who created the deck.
  final String userId;

  /// The title of the deck (e.g., 'Physics Midterm').
  final String title;

  /// The subject area of the deck.
  final String subject;

  /// Optional detailed description of the deck's content.
  final String? description;

  /// Whether the deck is public and accessible to other students.
  final bool isPublic;

  /// The date and time when the deck was created.
  final DateTime createdAt;

  /// Creates a [Deck] instance.
  Deck({
    required this.id,
    required this.userId,
    required this.title,
    required this.subject,
    this.description,
    this.isPublic = false,
    required this.createdAt,
  });

  /// Creates a [Deck] from a JSON-compatible map.
  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      subject: json['subject'],
      description: json['description'],
      isPublic: json['is_public'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Converts the [Deck] instance to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'subject': subject,
      'description': description,
      'is_public': isPublic,
    };
  }
}

/// Represents an individual flashcard within a deck.
class Flashcard {
  /// Unique identifier of the flashcard.
  final String id;

  /// The ID of the deck this flashcard belongs to.
  final String deckId;

  /// The text displayed on the front of the card.
  final String frontText;

  /// The text displayed on the back of the card.
  final String backText;

  /// Optional URL to an image associated with the flashcard.
  final String? imageUrl;

  /// Creates a [Flashcard] instance.
  Flashcard({
    required this.id,
    required this.deckId,
    required this.frontText,
    required this.backText,
    this.imageUrl,
  });

  /// Creates a [Flashcard] from a JSON-compatible map.
  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'],
      deckId: json['deck_id'],
      frontText: json['front_text'],
      backText: json['back_text'],
      imageUrl: json['image_url'],
    );
  }

  /// Converts the [Flashcard] instance to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'deck_id': deckId,
      'front_text': frontText,
      'back_text': backText,
      'image_url': imageUrl,
    };
  }
}
