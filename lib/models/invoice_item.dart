import 'package:gsheet/models/product.dart';

class InvoiceItem {
  final Product product;
  final int quantity;
  final int bonus;

  InvoiceItem({
    required this.product,
    required this.quantity,
    this.bonus = 0,
  });

  double get totalPrice => product.unitPrice * quantity;
}
