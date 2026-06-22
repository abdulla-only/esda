class Deck {
  final int id;
  final int language;
  final int owner;
  final String name;
  final String slug;
  final int order;
  final int cardCount;

  Deck({
    required this.id,
    required this.language,
    required this.owner,
    required this.name,
    required this.slug,
    required this.order,
    required this.cardCount,
  });

  factory Deck.fromJson(Map<String, dynamic> json) => Deck(
        id: json['id'] as int,
        language: json['language'] as int,
        owner: json['owner'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        order: json['order'] as int? ?? 0,
        cardCount: json['card_count'] as int? ?? 0,
      );
}
