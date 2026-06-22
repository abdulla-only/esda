class Language {
  final int id;
  final String code;
  final String name;

  Language({required this.id, required this.code, required this.name});

  factory Language.fromJson(Map<String, dynamic> json) => Language(
        id: json['id'] as int,
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}
