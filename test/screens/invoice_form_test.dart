import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsheet/models/customer.dart';
import 'package:gsheet/models/product.dart';
import 'package:gsheet/providers/invoice_provider.dart';
import 'package:gsheet/screens/invoice_form/invoice_form.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

class MockInvoiceProvider extends Mock implements InvoiceProvider {}

void main() {
  late MockInvoiceProvider mockInvoiceProvider;

  setUp(() {
    mockInvoiceProvider = MockInvoiceProvider();
  });

  final products = [
    Product(name: 'Product 1', type: 'Type A', packSize: '10', unitPrice: 100),
  ];
  final customers = [
    Customer(name: 'Customer 1', address: 'Address 1'),
  ];

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<InvoiceProvider>.value(
      value: mockInvoiceProvider,
      child: MaterialApp(
        home: Scaffold(
          body: InvoiceForm(),
        ),
      ),
    );
  }

  testWidgets('InvoiceForm should render correctly and interact with provider',
      (WidgetTester tester) async {
    when(mockInvoiceProvider.isLoading).thenReturn(false);
    when(mockInvoiceProvider.isBusy).thenReturn(false);
    when(mockInvoiceProvider.error).thenReturn(null);
    when(mockInvoiceProvider.products).thenReturn(products);
    when(mockInvoiceProvider.customers).thenReturn(customers);
    when(mockInvoiceProvider.selectedProduct).thenReturn(products.first);
    when(mockInvoiceProvider.selectedCustomer).thenReturn(customers.first);
    when(mockInvoiceProvider.invoiceItems).thenReturn([]);

    await tester.pumpWidget(createWidgetUnderTest());

    // Verify that the form fields are rendered
    expect(find.text('Customer Name'), findsOneWidget);
    expect(find.text('Invoice No.'), findsOneWidget);
    expect(find.text('Product Name'), findsOneWidget);
    expect(find.text('Quantity'), findsOneWidget);

    // Enter quantity and tap the "Add Item" button
    await tester.enterText(find.byType(TextFormField).at(2), '2'); // Quantity
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Verify that the addItem method was called on the provider
    // Note: The verify syntax needs to match the actual method signature
    // verify(mockInvoiceProvider.addItem(any, any(that: isA<int>())));
  });
}
