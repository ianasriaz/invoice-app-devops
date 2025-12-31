// ignore_for_file: deprecated_member_use
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:intl/intl.dart';
import 'package:gsheet/models/client.dart';
import 'package:gsheet/models/freelance_invoice.dart' as fi;
import 'package:gsheet/services/pdf_service.dart';
import 'package:gsheet/screens/create_invoice_screen.dart';
import 'package:gsheet/constants/app_colors.dart';

// Brand colors
const Color kBrandColor = AppColors.primary;
const Color kBackgroundColor = Color(0xFFF8F9FD);

enum InvoiceFilterStatus { all, draft, sent, unpaid, paid, overdue, cancelled }

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({Key? key}) : super(key: key);

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen> {
  final _firestore = FirebaseFirestore.instance;
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;
  InvoiceFilterStatus _selectedFilter = InvoiceFilterStatus.all;

  // --- HELPERS ---

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'cancelled':
        return Colors.red[300]!;
      default:
        return Colors.orange;
    }
  }

  fi.InvoiceStatus _mapStringToModelStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return fi.InvoiceStatus.paid;
      case 'overdue':
        return fi.InvoiceStatus.overdue;
      case 'cancelled':
        return fi.InvoiceStatus.cancelled;
      case 'sent':
        return fi.InvoiceStatus.sent;
      default:
        return fi.InvoiceStatus.draft;
    }
  }

  // --- ACTIONS ---

  Future<void> _updateInvoiceStatus(String invoiceId, String newStatus) async {
    HapticFeedback.lightImpact();
    try {
      await _firestore.collection('invoices').doc(invoiceId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked as ${newStatus.toUpperCase()}'),
            backgroundColor: _getStatusColor(newStatus),
            behavior: SnackBarBehavior.floating,
            width: 200,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  Future<void> _deleteInvoice(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Invoice'),
        content: const Text('This cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestore.collection('invoices').doc(id).delete();
    }
  }

  void _showStatusPicker(String invoiceId, String currentStatus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Update Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...['draft', 'sent', 'paid', 'cancelled'].map((status) {
              final isSelected = currentStatus == status;
              final color = _getStatusColor(status);
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.circle, size: 12, color: color),
                ),
                title: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? color : Colors.black87,
                  ),
                ),
                trailing: isSelected ? Icon(Icons.check, color: color) : null,
                onTap: () {
                  Navigator.pop(context);
                  if (!isSelected) _updateInvoiceStatus(invoiceId, status);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Invoices',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          // 1. Horizontal Filter Tabs
          Container(
            height: 60,
            color: Colors.white,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemCount: InvoiceFilterStatus.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = InvoiceFilterStatus.values[index];
                final isSelected = _selectedFilter == filter;
                return ChoiceChip(
                  label: Text(filter.name.toUpperCase()),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() => _selectedFilter = filter);
                      HapticFeedback.selectionClick();
                    }
                  },
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                  selectedColor: kBrandColor,
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                );
              },
            ),
          ),

          // 2. Invoice List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('invoices')
                  .where('userId', isEqualTo: _userId)
                  // Removed .orderBy('issueDate') to prevent Index Error
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: kBrandColor));
                }

                var docs = snapshot.data!.docs;

                // 1. Sort Client-Side (Newest First)
                // This replaces the database .orderBy() to avoid errors
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final dateA = aData['issueDate'] ?? '';
                  final dateB = bData['issueDate'] ?? '';
                  return dateB.compareTo(dateA); // Descending order
                });

                // 2. Apply Client-Side Filter
                if (_selectedFilter != InvoiceFilterStatus.all) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] as String? ?? 'draft';

                    if (_selectedFilter == InvoiceFilterStatus.overdue) {
                      final dueDateStr = data['dueDate'] as String?;
                      if (dueDateStr == null) return false;
                      final dueDate = DateTime.parse(dueDateStr);
                      return status != 'paid' &&
                          status != 'cancelled' &&
                          dueDate.isBefore(DateTime.now());
                    }

                    return status == _selectedFilter.name;
                  }).toList();
                }

                if (docs.isEmpty) return _buildEmptyState();

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _buildInvoiceCard(docs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
          );
        },
        backgroundColor: kBrandColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Invoice',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 60,
              color: kBrandColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No ${_selectedFilter.name} invoices',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final clientData = data['client'] as Map<String, dynamic>?;
    final clientName = clientData?['name'] ?? 'Unknown Client';
    final invoiceNum = data['invoiceNumber'] ?? '---';
    final total = double.tryParse(data['total']?.toString() ?? '0') ?? 0.0;
    final status = data['status'] as String? ?? 'draft';
    final issueDateStr = data['issueDate'] as String?;
    final issueDate =
        issueDateStr != null ? DateTime.parse(issueDateStr) : DateTime.now();

    final statusColor = _getStatusColor(status);

    final pdfInvoice = fi.FreelanceInvoice(
      id: doc.id,
      invoiceNumber: invoiceNum,
      client: Client(
          id: '',
          name: clientName,
          email: clientData?['email'] ?? '',
          phone: '',
          address: clientData?['address'] ?? ''),
      issueDate: issueDate,
      dueDate: DateTime.now(),
      items: [],
      status: _mapStringToModelStatus(status),
      taxRate: 0,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showStatusPicker(doc.id, status),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      invoiceNum,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          clientName.isNotEmpty
                              ? clientName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clientName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat.yMMMd().format(issueDate),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400],
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Rs ${total.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: kBrandColor,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            await PdfService.generateAndPrintInvoice(
                                pdfInvoice, pdfInvoice.client);
                          },
                          icon: Icon(Icons.picture_as_pdf_rounded,
                              color: Colors.grey[400]),
                          tooltip: 'Generate PDF',
                        ),
                        IconButton(
                          onPressed: () => _deleteInvoice(doc.id),
                          icon: Icon(Icons.delete_outline_rounded,
                              color: Colors.red[300]),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
