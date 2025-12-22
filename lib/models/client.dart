class Client {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? company;

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.company,
  });

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      company: map['company'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'company': company,
    };
  }

  @override
  String toString() =>
      company != null && company!.isNotEmpty ? '$name ($company)' : name;
}
