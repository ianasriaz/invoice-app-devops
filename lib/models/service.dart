class Service {
  final String id;
  final String name;
  final String description;
  final double rate;
  final String unit; // 'hour', 'day', 'project', etc.

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.rate,
    required this.unit,
  });

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      rate: double.parse(map['rate'].toString()),
      unit: map['unit'] ?? 'hour',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rate': rate,
      'unit': unit,
    };
  }
}
