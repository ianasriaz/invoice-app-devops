import 'package:gsheet/models/client.dart';
import 'package:gsheet/models/invoice_line_item.dart';

enum InvoiceStatus { draft, sent, paid, overdue, cancelled }

class FreelanceInvoice {
  final String id;
  final String invoiceNumber;
  final Client client;
  final DateTime issueDate;
  final DateTime dueDate;
  final List<InvoiceLineItem> items;
  final InvoiceStatus status;
  final double taxRate; // percentage
  final String? notes;
  final String? termsAndConditions;

  FreelanceInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.client,
    required this.issueDate,
    required this.dueDate,
    required this.items,
    this.status = InvoiceStatus.draft,
    this.taxRate = 0.0,
    this.notes,
    this.termsAndConditions,
  });

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get taxAmount => subtotal * (taxRate / 100);

  double get total => subtotal + taxAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'client': client.toMap(),
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'status': status.toString().split('.').last,
      'taxRate': taxRate,
      'notes': notes,
      'termsAndConditions': termsAndConditions,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'total': total,
    };
  }

  factory FreelanceInvoice.fromMap(Map<String, dynamic> map) {
    return FreelanceInvoice(
      id: map['id'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      client: Client.fromMap(map['client'] ?? {}),
      issueDate: DateTime.parse(map['issueDate']),
      dueDate: DateTime.parse(map['dueDate']),
      items: [], // Would need to reconstruct items
      status: InvoiceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      taxRate: double.parse(map['taxRate']?.toString() ?? '0'),
      notes: map['notes'],
      termsAndConditions: map['termsAndConditions'],
    );
  }

  FreelanceInvoice copyWith({
    String? id,
    String? invoiceNumber,
    Client? client,
    DateTime? issueDate,
    DateTime? dueDate,
    List<InvoiceLineItem>? items,
    InvoiceStatus? status,
    double? taxRate,
    String? notes,
    String? termsAndConditions,
  }) {
    return FreelanceInvoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      client: client ?? this.client,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      status: status ?? this.status,
      taxRate: taxRate ?? this.taxRate,
      notes: notes ?? this.notes,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
    );
  }
}
