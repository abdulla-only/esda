/// A deck card. Named DeckCard to avoid clashing with Material's [Card] widget.
class DeckCard {
  final int id;
  final int deck;
  final String front;
  final String back;
  final String description;
  final String example;
  final String partOfSpeech;
  final int order;

  DeckCard({
    required this.id,
    required this.deck,
    required this.front,
    required this.back,
    required this.description,
    required this.example,
    required this.partOfSpeech,
    required this.order,
  });

  factory DeckCard.fromJson(Map<String, dynamic> json) => DeckCard(
        id: json['id'] as int,
        deck: json['deck'] as int? ?? 0,
        front: json['front'] as String? ?? '',
        back: json['back'] as String? ?? '',
        description: json['description'] as String? ?? '',
        example: json['example'] as String? ?? '',
        partOfSpeech: json['part_of_speech'] as String? ?? 'other',
        order: json['order'] as int? ?? 0,
      );
}

/// Allowed part_of_speech values (mirrors the backend enum).
const partsOfSpeech = ['noun', 'verb', 'adjective', 'adverb', 'phrase', 'other'];
