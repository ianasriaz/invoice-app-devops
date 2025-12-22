import 'package:flutter/material.dart';
import 'package:gsheet/constants/app_colors.dart';

import 'package:gsheet/models/customer.dart';
import 'package:gsheet/models/product.dart';
import 'package:gsheet/providers/invoice_provider.dart';
import 'package:provider/provider.dart';

class InvoiceForm extends StatefulWidget {
  final bool skipInitialLoad;

  const InvoiceForm({Key? key, this.skipInitialLoad = false}) : super(key: key);

  @override
  _InvoiceFormState createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<InvoiceForm> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _bonus_controller = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _invoiceNumberController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (!widget.skipInitialLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<InvoiceProvider>(context, listen: false).loadInitialData();
      });
    }
    _bonus_controller.text = '0';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _bonus_controller.dispose();
    _typeController.dispose();
    _invoiceNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InvoiceProvider>(
      builder: (context, invoiceProvider, child) {
        if (invoiceProvider.error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(invoiceProvider.error!)),
            );
          });
        }

        if (invoiceProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (invoiceProvider.isBusy) {
          return Center(
              child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ));
        }

        if (invoiceProvider.selectedProduct != null) {
          _typeController.text =
              '${invoiceProvider.selectedProduct!.type} - ${invoiceProvider.selectedProduct!.packSize}    |    Price: ${invoiceProvider.selectedProduct!.unitPrice}';
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<Customer>(
                  isExpanded: true,
                  value: invoiceProvider.selectedCustomer,
                  items: invoiceProvider.customers
                      .map(
                        (e) => DropdownMenuItem(
                          child: Text(e.toString()),
                          value: e,
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    invoiceProvider.selectCustomer(value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    hintText: 'Select a customer',
                  ),
                  validator: (value) {
                    if (value == null) return 'Please select a customer';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _invoiceNumberController,
                  decoration: const InputDecoration(labelText: 'Invoice No.'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Invoice No. Can\'t be empty';
                    return null;
                  },
                  onChanged: (value) {
                    invoiceProvider.setInvoiceNumber(value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Product>(
                  value: invoiceProvider.selectedProduct,
                  items: invoiceProvider.products
                      .map(
                        (e) => DropdownMenuItem(
                          child: Text(e.name),
                          value: e,
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    invoiceProvider.selectProduct(value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    hintText: 'Select a product',
                  ),
                  validator: (value) {
                    if (value == null) return 'Please select a product';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _typeController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration:
                            const InputDecoration(labelText: 'Quantity'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty || int.tryParse(value) == null)
                            return 'Please enter a valid quanitity';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _bonus_controller,
                        decoration: const InputDecoration(labelText: 'Bonus'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate() &&
                          invoiceProvider.selectedProduct != null) {
                        invoiceProvider.addItem(
                          int.parse(_quantityController.text),
                          int.tryParse(_bonus_controller.text) ?? 0,
                        );
                        _quantityController.clear();
                        _bonus_controller.clear();
                        _bonus_controller.text = '0';
                        FocusManager.instance.primaryFocus?.unfocus();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Item added'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
                if (invoiceProvider.invoiceItems.isNotEmpty) ...[
                  Text('Invoice Items',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Divider(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: invoiceProvider.invoiceItems.length,
                    itemBuilder: (context, index) {
                      final item = invoiceProvider.invoiceItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(item.quantity.toString()),
                          ),
                          title: Text(item.product.name),
                          subtitle: Text(
                              'Price: ${item.product.unitPrice.toStringAsFixed(2)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              invoiceProvider.removeItem(index);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Item Deleted'),
                                    duration: Duration(seconds: 1)),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTotalRow('Subtotal:', invoiceProvider.subtotal),
                          _buildTotalRow('VAT (15%):', invoiceProvider.tax),
                          const Divider(),
                          _buildTotalRow(
                              'Total Payable:', invoiceProvider.total,
                              isTotal: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final invoice =
                              await invoiceProvider.saveInvoiceOnly();
                          if (invoice != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Invoice ${invoice.invoiceNumber} saved successfully!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            invoiceProvider.clearForm();
                            _invoiceNumberController.clear();
                          }
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save Invoice'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        invoiceProvider.clearForm();
                        _invoiceNumberController.clear();
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('New Invoice'),
                    ),
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${value.toStringAsFixed(2)} TK',
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
