import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:gsheet/models/client.dart';
import 'package:gsheet/models/freelance_invoice.dart';
import 'package:gsheet/models/invoice_line_item.dart';
import 'package:gsheet/models/service.dart';
import 'package:intl/intl.dart';
import 'package:gsheet/constants/app_colors.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({Key? key}) : super(key: key);

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen>
    with TickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  String get _userId => FirebaseAuth.instance.currentUser!.uid;

  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _termsController = TextEditingController(
    text: 'Payment is due within 30 days.\nThank you for your business!',
  );

  Client? _selectedClient;
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  double _taxRate = 0.0;
  final List<InvoiceLineItem> _lineItems = [];

  bool _isLoading = false;
  late AnimationController _pageController;
  late Animation<double> _pageAnimation;

  // Colors
  final Color _brandColor = AppColors.primary;
  final Color _brandColorDark = const Color(0xFF4A148C);

  @override
  void initState() {
    super.initState();
    _generateInvoiceNumber();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pageAnimation = CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeOutCubic,
    );

    _pageController.forward();
  }

  void _generateInvoiceNumber() {
    final now = DateTime.now();
    _invoiceNumberController.text =
        'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
  }

  Future<void> _selectDate(BuildContext context, bool isIssueDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isIssueDate ? _issueDate : _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _brandColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  void _showAddServiceDialog() {
    String? selectedServiceId;
    Service? selectedService;
    final quantityController = TextEditingController(text: '1');
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Service Line Item',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('services')
                    .where('userId', isEqualTo: _userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return const Text('Error loading services');
                  if (!snapshot.hasData) return const LinearProgressIndicator();

                  final services = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Service(
                      id: doc.id,
                      name: data['name'] ?? '',
                      description: data['description'] ?? '',
                      rate: double.parse(data['rate']?.toString() ?? '0'),
                      unit: data['unit'] ?? 'hour',
                    );
                  }).toList();

                  if (services.isEmpty) {
                    return Center(
                      child: Text(
                        'No services found. Create one first.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    value: selectedServiceId,
                    hint: const Text('Select a Service'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    items: services.map((service) {
                      return DropdownMenuItem(
                        value: service.id,
                        child: Text(service.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedServiceId = val;
                        selectedService =
                            services.firstWhere((s) => s.id == val);
                      });
                    },
                  );
                },
              ),
              if (selectedService != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _brandColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _brandColor.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rate: Rs ${selectedService!.rate.toStringAsFixed(0)} / ${selectedService!.unit}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _brandColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Item Notes (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedService == null) return;
                      this.setState(() {
                        _lineItems.add(InvoiceLineItem(
                          service: selectedService!,
                          quantity:
                              double.tryParse(quantityController.text) ?? 1,
                          notes: notesController.text.isEmpty
                              ? null
                              : notesController.text,
                        ));
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Add Item',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Calculation Getters
  double get _subtotal =>
      _lineItems.fold(0, (sum, item) => sum + item.totalPrice);
  double get _taxAmount => _subtotal * (_taxRate / 100);
  double get _total => _subtotal + _taxAmount;

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a client')));
      return;
    }
    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item')));
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final invoice = FreelanceInvoice(
        id: '', // Generated by Firestore
        invoiceNumber: _invoiceNumberController.text,
        client: _selectedClient!,
        issueDate: _issueDate,
        dueDate: _dueDate,
        items: _lineItems,
        status: InvoiceStatus.draft,
        taxRate: _taxRate,
        notes: _notesController.text,
        termsAndConditions: _termsController.text,
      );

      await _firestore.collection('invoices').add({
        ...invoice.toMap(),
        'userId': _userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('New Invoice',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _pageAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Invoice Basics Card
                _buildSectionCard(
                  title: 'Invoice Details',
                  icon: Icons.receipt_long_rounded,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _invoiceNumberController,
                        decoration: InputDecoration(
                          labelText: 'Invoice Number',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateSelector(
                                'Issue Date', _issueDate, true),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child:
                                _buildDateSelector('Due Date', _dueDate, false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Client Selection Card
                _buildSectionCard(
                  title: 'Bill To',
                  icon: Icons.person_rounded,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('clients')
                        .where('userId', isEqualTo: _userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const LinearProgressIndicator();

                      final clients = snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Client(
                          id: doc.id,
                          name: data['name'] ?? '',
                          email: data['email'] ?? '',
                          phone: data['phone'] ?? '',
                          address: data['address'] ?? '',
                          company: data['company'],
                        );
                      }).toList();

                      return DropdownButtonFormField<String>(
                        value: _selectedClient?.id,
                        hint: const Text('Select Client'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: clients
                            .map((c) => DropdownMenuItem(
                                value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedClient =
                                clients.firstWhere((c) => c.id == val);
                          });
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Line Items Card
                _buildSectionCard(
                  title: 'Services',
                  icon: Icons.list_alt_rounded,
                  child: Column(
                    children: [
                      if (_lineItems.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(Icons.add_shopping_cart_rounded,
                                  size: 40, color: Colors.grey[300]),
                              const SizedBox(height: 8),
                              Text('No items added yet',
                                  style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _lineItems.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = _lineItems[index];
                            return ListTile(
                              title: Text(item.service.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  '${item.quantity} x Rs ${item.service.rate}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                      'Rs ${item.totalPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red),
                                    onPressed: () => setState(
                                        () => _lineItems.removeAt(index)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _showAddServiceDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Line Item'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _brandColor,
                          side: BorderSide(color: _brandColor),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Totals & Tax Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_brandColor, _brandColorDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _brandColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Tax Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax Rate',
                              style: TextStyle(color: Colors.white70)),
                          Text('${_taxRate.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8),
                          overlayColor: Colors.white12,
                        ),
                        child: Slider(
                          value: _taxRate,
                          min: 0,
                          max: 30,
                          divisions: 30,
                          onChanged: (val) => setState(() => _taxRate = val),
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 32),
                      _buildTotalRow('Subtotal', _subtotal),
                      const SizedBox(height: 8),
                      _buildTotalRow(
                          'Tax (${_taxRate.toStringAsFixed(0)}%)', _taxAmount),
                      const SizedBox(height: 16),
                      _buildTotalRow('Total Amount', _total, isTotal: true),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 5. Notes & Terms
                _buildSectionCard(
                  title: 'Additional Info',
                  icon: Icons.note_alt_rounded,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _termsController,
                        decoration: InputDecoration(
                          labelText: 'Terms & Conditions',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 6. Generate Invoice Button (Full Width)
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [_brandColor, _brandColorDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _brandColor.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _saveInvoice,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Generate Invoice',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Icon(icon, color: _brandColor, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime date, bool isIssueDate) {
    return InkWell(
      onTap: () => _selectDate(context, isIssueDate),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: Colors.black87),
                const SizedBox(width: 8),
                Text(
                  DateFormat.yMMMd().format(date),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          'Rs ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTotal ? 22 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
