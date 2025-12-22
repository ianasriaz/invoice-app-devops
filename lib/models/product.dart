class Product {
  final String name;
  final String type;
  final String packSize;
  final double unitPrice;

  Product({
    required this.name,
    required this.type,
    required this.packSize,
    required this.unitPrice,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      name: map['Product Name'],
      type: map['Type'],
      packSize: map['Pack size'],
      unitPrice: double.parse(map['Unit Price'].toString()),
    );
  }
}
