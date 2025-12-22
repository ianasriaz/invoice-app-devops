import 'package:flutter/material.dart';
import 'package:gsheet/models/customer.dart';
import 'package:gsheet/models/invoice.dart';
import 'package:gsheet/models/invoice_item.dart';
import 'package:gsheet/models/product.dart';
import 'package:gsheet/services/firebase_service.dart';
import 'package:gsheet/services/pdf_service.dart';
import 'package:logger/logger.dart';

/// Manages the state of the invoice creation process.
///
/// This provider handles the business logic for creating, managing,
/// and saving invoices. It interacts with the [FirebaseService] and
/// [PdfService] to handle data persistence and PDF generation.
class InvoiceProvider with ChangeNotifier {
  late final FirebaseService _firebaseService;
  final _logger = Logger();

  /// Creates an instance of [InvoiceProvider].
  ///
  /// An optional [firebaseService] can be provided for testing purposes.
  InvoiceProvider({FirebaseService? firebaseService}) {
    _firebaseService = firebaseService ?? FirebaseService();
  }

  List<Product> _products = [];
  List<Customer> _customers = [];
  List<InvoiceItem> _invoiceItems = [];
  String _signUrl = '';
  bool _isLoading = false;
  String? _error;
  bool _isBusy = false;

  /// The list of available products.
  List<Product> get products => _products;

  /// The list of available customers.
  List<Customer> get customers => _customers;

  /// The list of items currently in the invoice.
  List<InvoiceItem> get invoiceItems => _invoiceItems;

  /// The URL for the signature image.
  String get signUrl => _signUrl;

  /// Whether the initial data is being loaded.
  bool get isLoading => _isLoading;

  /// The current error message, if any.
  String? get error => _error;

  /// Whether the provider is busy with a task (e.g., saving an invoice).
  bool get isBusy => _isBusy;

  /// The currently selected customer.
  Customer? selectedCustomer;

  /// The currently selected product to be added to the invoice.
  Product? selectedProduct;

  /// The current invoice number.
  String invoiceNumber = '';

  /// Clears the current invoice form.
  void clearForm() {
    _invoiceItems.clear();
    invoiceNumber = '';
    notifyListeners();
    _logger.i('Form cleared.');
  }

  /// Creates and saves the current invoice to Firestore.
  ///
  /// Returns the created [Invoice] on success, or `null` on failure.
  Future<Invoice?> _createAndSaveInvoice() async {
    if (selectedCustomer == null ||
        invoiceNumber.isEmpty ||
        _invoiceItems.isEmpty) {
      _error = 'Please fill all fields and add at least one item.';
      notifyListeners();
      return null;
    }

    _isBusy = true;
    _error = null;
    notifyListeners();

    final invoice = Invoice(
      invoiceNumber: invoiceNumber,
      customer: selectedCustomer!,
      date: DateTime.now(),
      items: _invoiceItems,
      signUrl: _signUrl,
    );

    try {
      await _firebaseService.saveInvoice(invoice);
      _isBusy = false;
      notifyListeners();
      return invoice;
    } catch (e, s) {
      _logger.e('Failed to save invoice', e, s);
      _error = 'Failed to save invoice. Please try again.';
      _isBusy = false;
      notifyListeners();
      return null;
    }
  }

  /// Saves the invoice to Firestore without generating a PDF.
  /// This is useful for web where PDF generation is not supported.
  Future<Invoice?> saveInvoiceOnly() async {
    return await _createAndSaveInvoice();
  }

  /// Generates a preview of the current invoice.
  Future<void> previewInvoice() async {
    // Legacy method - no longer used in new freelancer invoice system
    _logger.i('Preview invoice - feature not implemented for legacy provider');
  }

  /// Shares the current invoice as a PDF.
  Future<void> shareInvoice() async {
    // Legacy method - no longer used in new freelancer invoice system
    _logger.i('Share invoice - feature not implemented for legacy provider');
  }

  /// Loads the initial data (products, customers, etc.) from Firestore.
  Future<void> loadInitialData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _firebaseService.fetchData();
      _products = data['products'];
      _customers = data['customers'];
      _signUrl = data['signUrl'];
      // Don't auto-select to give user better control
      _logger.i('Initial data loaded successfully.');
    } catch (e, s) {
      _logger.e('Failed to load initial data', e, s);
      _error = 'Failed to load data. Please check your internet connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets the selected customer.
  void selectCustomer(Customer? customer) {
    selectedCustomer = customer;
    notifyListeners();
  }

  /// Sets the selected product.
  void selectProduct(Product? product) {
    selectedProduct = product;
    notifyListeners();
  }

  /// Sets the invoice number.
  void setInvoiceNumber(String number) {
    invoiceNumber = number;
  }

  /// Adds an item to the current invoice.
  void addItem(int quantity, int bonus) {
    if (selectedProduct != null) {
      _invoiceItems.add(InvoiceItem(
        product: selectedProduct!,
        quantity: quantity,
        bonus: bonus,
      ));
      notifyListeners();
      _logger.i('Added item: ${selectedProduct!.name}');
    }
  }

  /// Removes an item from the current invoice.
  void removeItem(int index) {
    if (index >= 0 && index < _invoiceItems.length) {
      final item = _invoiceItems[index];
      _invoiceItems.removeAt(index);
      notifyListeners();
      _logger.i('Removed item: ${item.product.name}');
    }
  }

  /// The subtotal of the invoice (before tax).
  double get subtotal {
    return _invoiceItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// The tax amount of the invoice.
  double get tax => subtotal * 0.15;

  /// The total amount of the invoice (including tax).
  double get total => subtotal + tax;
}
