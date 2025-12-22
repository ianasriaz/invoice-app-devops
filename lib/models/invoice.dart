import 'package:gsheet/models/customer.dart';
import 'package:gsheet/models/invoice_item.dart';

class Invoice {
  final String invoiceNumber;
  final Customer customer;
  final DateTime date;
  final List<InvoiceItem> items;
  final String signUrl;

  Invoice({
    required this.invoiceNumber,
    required this.customer,
    required this.date,
    required this.items,
    required this.signUrl,
  });

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get tax => subtotal * 0.15;

  double get total => subtotal + tax;
}
