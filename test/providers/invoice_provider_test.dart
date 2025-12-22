import 'package:flutter_test/flutter_test.dart';
import 'package:gsheet/models/customer.dart';
import 'package:gsheet/models/product.dart';
import 'package:gsheet/providers/invoice_provider.dart';
import 'package:gsheet/services/firebase_service.dart';
import 'package:mockito/mockito.dart';

class MockFirebaseService extends Mock implements FirebaseService {}

void main() {
  late InvoiceProvider invoiceProvider;
  late MockFirebaseService mockFirebaseService;

  setUp(() {
    mockFirebaseService = MockFirebaseService();
    invoiceProvider = InvoiceProvider(firebaseService: mockFirebaseService);
  });

  group('InvoiceProvider', () {
    final products = [
      Product(name: 'Product 1', type: 'Type A', packSize: '10', unitPrice: 100),
      Product(name: 'Product 2', type: 'Type B', packSize: '20', unitPrice: 200),
    ];
    final customers = [
      Customer(name: 'Customer 1', address: 'Address 1'),
      Customer(name: 'Customer 2', address: 'Address 2'),
    ];
    final signUrl = 'http://example.com/sign.png';

    test('loadInitialData should fetch data and update state', () async {
      when(mockFirebaseService.fetchData()).thenAnswer((_) async => {
            'products': products,
            'customers': customers,
            'signUrl': signUrl,
          });

      await invoiceProvider.loadInitialData();

      expect(invoiceProvider.products, products);
      expect(invoiceProvider.customers, customers);
      expect(invoiceProvider.signUrl, signUrl);
      expect(invoiceProvider.isLoading, false);
      expect(invoiceProvider.error, null);
    });

    test('addItem should add an item to the invoice', () {
      invoiceProvider.selectProduct(products.first);
      invoiceProvider.addItem(2, 1);

      expect(invoiceProvider.invoiceItems.length, 1);
      expect(invoiceProvider.invoiceItems.first.product, products.first);
      expect(invoiceProvider.invoiceItems.first.quantity, 2);
      expect(invoiceProvider.invoiceItems.first.bonus, 1);
    });

    test('removeItem should remove an item from the invoice', () {
      invoiceProvider.selectProduct(products.first);
      invoiceProvider.addItem(2, 1);
      invoiceProvider.removeItem(0);

      expect(invoiceProvider.invoiceItems.length, 0);
    });

    test('total should be calculated correctly', () {
      invoiceProvider.selectProduct(products.first); // price 100
      invoiceProvider.addItem(2, 0);
      invoiceProvider.selectProduct(products.last); // price 200
      invoiceProvider.addItem(1, 0);

      // subtotal = (100 * 2) + (200 * 1) = 400
      // tax = 400 * 0.15 = 60
      // total = 400 + 60 = 460
      expect(invoiceProvider.subtotal, 400);
      expect(invoiceProvider.tax, 60);
      expect(invoiceProvider.total, 460);
    });

    test('clearForm should clear the invoice items and number', () {
      invoiceProvider.selectProduct(products.first);
      invoiceProvider.addItem(2, 1);
      invoiceProvider.setInvoiceNumber('123');

      invoiceProvider.clearForm();

      expect(invoiceProvider.invoiceItems.isEmpty, true);
      expect(invoiceProvider.invoiceNumber, '');
    });
  });
}
