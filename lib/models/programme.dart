class Programme {
  final String id;
  final String code;
  final String name;

  Programme({
    this.id = '',
    required this.code,
    required this.name,
  });

  factory Programme.fromMap(Map<String, dynamic> data, {String id = ''}) {
    return Programme(
      id: id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
    );
  }
}