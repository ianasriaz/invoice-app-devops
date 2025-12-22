import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gsheet/models/customer.dart';
import 'package:gsheet/models/invoice.dart';
import 'package:gsheet/models/product.dart';
import 'package:logger/logger.dart';

/// A service that handles all interactions with Firebase.
///
/// This service is responsible for fetching data from and saving data to
/// Cloud Firestore.
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  /// Fetches the initial data (products, customers, etc.) from Firestore.
  ///
  /// Returns a map containing the fetched data.
  Future<Map<String, dynamic>> fetchData() async {
    try {
      _logger.i('Fetching data from Firestore...');
      // Fetch products
      final productSnapshot = await _firestore.collection('products').get();
      final products = productSnapshot.docs
          .map((doc) => Product.fromMap(doc.data()))
          .toList();

      // Fetch customers
      final customerSnapshot = await _firestore.collection('customers').get();
      final customers = customerSnapshot.docs
          .map((doc) => Customer.fromMap(doc.data()))
          .toList();

      // Fetch resources (e.g., signUrl)
      final resourcesSnapshot =
          await _firestore.collection('resources').doc('config').get();
      final signUrl = resourcesSnapshot.data()?['signURL'] ?? '';

      _logger.i('Data fetched successfully.');
      return {
        'products': products,
        'customers': customers,
        'signUrl': signUrl,
      };
    } catch (e, s) {
      _logger.e('Failed to load data from Firestore', e, s);
      throw Exception('Failed to load data from Firestore');
    }
  }

  /// Saves an invoice to Firestore.
  ///
  /// The invoice data is saved in a transaction to ensure data integrity.
  Future<void> saveInvoice(Invoice invoice) async {
    try {
      _logger.i('Saving invoice ${invoice.invoiceNumber} to Firestore...');
      final invoiceRef =
          _firestore.collection('invoices').doc(invoice.invoiceNumber);

      await _firestore.runTransaction((transaction) async {
        // Save the main invoice document
        transaction.set(invoiceRef, {
          'invoiceNumber': invoice.invoiceNumber,
          'customerName': invoice.customer.name,
          'customerAddress': invoice.customer.address,
          'date': invoice.date,
          'total': invoice.total,
        });

        // Save the invoice items in a subcollection
        final itemsCollection = invoiceRef.collection('items');
        for (var item in invoice.items) {
          final itemRef =
              itemsCollection.doc(); // Auto-generate ID for each item
          transaction.set(itemRef, {
            'productName': item.product.name,
            'productType': item.product.type,
            'packSize': item.product.packSize,
            'unitPrice': item.product.unitPrice,
            'quantity': item.quantity,
            'bonus': item.bonus,
          });
        }
      });
      _logger.i('Invoice ${invoice.invoiceNumber} saved successfully.');
    } catch (e, s) {
      _logger.e('Failed to save invoice to Firestore', e, s);
      throw Exception('Failed to save invoice to Firestore');
    }
  }
}
