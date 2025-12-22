import 'package:gsheet/models/service.dart';

class InvoiceLineItem {
  final Service service;
  final double quantity;
  final String? notes;

  InvoiceLineItem({
    required this.service,
    required this.quantity,
    this.notes,
  });

  double get totalPrice => service.rate * quantity;

  Map<String, dynamic> toMap() {
    return {
      'serviceId': service.id,
      'serviceName': service.name,
      'description': service.description,
      'rate': service.rate,
      'unit': service.unit,
      'quantity': quantity,
      'notes': notes,
      'total': totalPrice,
    };
  }
}
