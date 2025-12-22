import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsheet/models/customer.dart';
import 'package:gsheet/models/product.dart';
import 'package:gsheet/models/invoice_item.dart';
import 'package:gsheet/providers/invoice_provider.dart';
import 'package:gsheet/screens/invoice_form/invoice_form.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

class MockInvoiceProvider extends Mock implements InvoiceProvider {
  @override
  bool get isLoading =>
      super.noSuchMethod(Invocation.getter(#isLoading), returnValue: false);

  @override
  bool get isBusy =>
      super.noSuchMethod(Invocation.getter(#isBusy), returnValue: false);

  @override
  String? get error =>
      super.noSuchMethod(Invocation.getter(#error), returnValue: null);

  @override
  List<Product> get products =>
      super.noSuchMethod(Invocation.getter(#products), returnValue: <Product>[])
          as List<Product>;

  @override
  List<Customer> get customers =>
      super.noSuchMethod(Invocation.getter(#customers),
          returnValue: <Customer>[]) as List<Customer>;

  @override
  List<InvoiceItem> get invoiceItems =>
      super.noSuchMethod(Invocation.getter(#invoiceItems),
          returnValue: <InvoiceItem>[]) as List<InvoiceItem>;

  @override
  Customer? get selectedCustomer => super
          .noSuchMethod(Invocation.getter(#selectedCustomer), returnValue: null)
      as Customer?;

  @override
  Product? get selectedProduct =>
      super.noSuchMethod(Invocation.getter(#selectedProduct), returnValue: null)
          as Product?;
}

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
          body: InvoiceForm(skipInitialLoad: true),
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
    await tester.pumpAndSettle();

    // Verify that the form fields are rendered
    expect(find.text('Customer Name'), findsOneWidget);
    expect(find.text('Invoice No.'), findsOneWidget);
    expect(find.text('Product Name'), findsOneWidget);
    expect(find.text('Quantity'), findsOneWidget);

    // Satisfy validators
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Invoice No.'), '123');

    // Enter quantity for completeness (no tap to avoid dependency on button wiring)
    await tester.enterText(find.byType(TextFormField).at(2), '2');
  });
}
