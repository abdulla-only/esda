class StudyCard {
  final int id;
  final String front;
  final String back;
  final String description;
  final String example;
  final String partOfSpeech;
  final bool isNew;

  StudyCard({
    required this.id,
    required this.front,
    required this.back,
    required this.description,
    required this.example,
    required this.partOfSpeech,
    required this.isNew,
  });

  factory StudyCard.fromJson(Map<String, dynamic> json) {
    final review = (json['review'] as Map<String, dynamic>?) ?? const {};
    return StudyCard(
      id: json['id'] as int,
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
      description: json['description'] as String? ?? '',
      example: json['example'] as String? ?? '',
      partOfSpeech: json['part_of_speech'] as String? ?? 'other',
      isNew: review['is_new'] as bool? ?? true,
    );
  }
}
