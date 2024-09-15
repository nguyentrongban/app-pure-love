class House {
  final int id;
  final String key;
  final String nameA;
  final String? nameB;
  final String? imageA;
  final String? imageB;
  final DateTime startDate;

  House({
    required this.id,
    required this.key,
    required this.nameA,
    this.nameB,
    this.imageA,
    this.imageB,
    required this.startDate,
  });

  factory House.fromJson(Map<String, dynamic> json) {
    return House(
      id: json['id'],
      key: json['key'],
      nameA: json['name_a'],
      nameB: json['name_b'],
      imageA: json['image_a'],
      imageB: json['image_b'],
      startDate: DateTime.parse(json['start_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'name_a': nameA,
      'name_b': nameB,
      'image_a': imageA,
      'image_b': imageB,
      'start_date': startDate.toIso8601String(),
    };
  }
}
