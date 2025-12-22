class Customer {
  final String name;
  final String address;

  Customer({required this.name, required this.address});

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      name: map['Party Name'],
      address: map['Address'],
    );
  }

  @override
  String toString() => '$name-$address';
}
