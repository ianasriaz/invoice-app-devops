// ignore_for_file: deprecated_member_use
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gsheet/models/client.dart';
import 'package:gsheet/models/freelance_invoice.dart' as fi;
import 'package:gsheet/models/invoice_line_item.dart';
import 'package:gsheet/models/service.dart';
import 'package:gsheet/services/pdf_service.dart';
import 'package:gsheet/screens/create_invoice_screen.dart';
import 'package:gsheet/constants/app_colors.dart';

const Color kBrandColor = AppColors.primary;
const Color kBrandColorLight = AppColors.primaryLight;
const Color kBackgroundColor = AppColors.lightBackground;

enum InvoiceFilterStatus { draft, unpaid, paid, overdue, cancelled, sent }

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({Key? key}) : super(key: key);

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen> {
  final _firestore = FirebaseFirestore.instance;
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;
  InvoiceFilterStatus? _filterStatus;

  Color _getStatusColor(InvoiceFilterStatus status) {
    switch (status) {
      case InvoiceFilterStatus.draft:
        return AppColors.statusDraft;
      case InvoiceFilterStatus.unpaid:
        return AppColors.warning;
      case InvoiceFilterStatus.paid:
        return AppColors.statusPaid;
      case InvoiceFilterStatus.overdue:
        return AppColors.statusOverdue;
      case InvoiceFilterStatus.cancelled:
        return AppColors.statusCancelled;
      case InvoiceFilterStatus.sent:
        return AppColors.statusSent;
    }
  }

  IconData _getStatusIcon(InvoiceFilterStatus status) {
    switch (status) {
      case InvoiceFilterStatus.draft:
        return Icons.edit_note_rounded;
      case InvoiceFilterStatus.unpaid:
        return Icons.hourglass_top_rounded;
      case InvoiceFilterStatus.paid:
        return Icons.check_circle_rounded;
      case InvoiceFilterStatus.overdue:
        return Icons.error_outline_rounded;
      case InvoiceFilterStatus.cancelled:
        return Icons.cancel_outlined;
      case InvoiceFilterStatus.sent:
        return Icons.send_rounded;
    }
  }

  fi.InvoiceStatus _mapFilterToModelStatus(InvoiceFilterStatus status) {
    switch (status) {
      case InvoiceFilterStatus.paid:
        return fi.InvoiceStatus.paid;
      case InvoiceFilterStatus.overdue:
        return fi.InvoiceStatus.overdue;
      case InvoiceFilterStatus.cancelled:
        return fi.InvoiceStatus.cancelled;
      case InvoiceFilterStatus.sent:
        return fi.InvoiceStatus.sent;
      case InvoiceFilterStatus.unpaid:
        return fi.InvoiceStatus.draft;
      case InvoiceFilterStatus.draft:
      default:
        return fi.InvoiceStatus.draft;
    }
  }

  Future<void> _updateInvoiceStatus(
      String invoiceId, InvoiceFilterStatus newStatus) async {
    try {
      await _firestore.collection('invoices').doc(invoiceId).update({
        'status': newStatus.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invoice status updated'),
            backgroundColor: _getStatusColor(newStatus),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showStatusDialog(String invoiceId, InvoiceFilterStatus currentStatus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Update Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            ...InvoiceFilterStatus.values.map((status) {
              final isSelected = currentStatus == status;
              final color = _getStatusColor(status);
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: color,
                    size: 20,
                  ),
                ),
                title: Text(
                  status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? color : Colors.black87,
                  ),
                ),
                trailing: isSelected ? Icon(Icons.check, color: color) : null,
                onTap: () {
                  Navigator.pop(context);
                  _updateInvoiceStatus(invoiceId, status);
                },
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteInvoice(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Invoice'),
        content: const Text(
            'Are you sure you want to delete this invoice? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('invoices').doc(id).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Invoice deleted'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: AppColors.lightText,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Invoices',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Theme(
            data: Theme.of(context).copyWith(
              cardColor: AppColors.lightSurface,
            ),
            child: PopupMenuButton<InvoiceFilterStatus?>(
              icon: const Icon(Icons.filter_list_rounded,
                  color: AppColors.primary),
              tooltip: 'Filter',
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (status) {
                setState(() => _filterStatus = status);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('Show All'),
                ),
                const PopupMenuDivider(),
                ...InvoiceFilterStatus.values.map((status) {
                  return PopupMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Icon(_getStatusIcon(status),
                            color: _getStatusColor(status), size: 18),
                        const SizedBox(width: 12),
                        Text(status.toString().split('.').last.toUpperCase()),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: (_userId == null)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Please sign in to view your invoices'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: Text('Sign In'),
                  ),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('invoices')
                  .where('userId', isEqualTo: _userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(color: kBrandColor));
                }

                var invoices = snapshot.data!.docs;

                // Apply filter
                if (_filterStatus != null) {
                  invoices = invoices.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final statusStr = data['status'] as String?;
                    return statusStr ==
                        _filterStatus.toString().split('.').last;
                  }).toList();
                }

                if (invoices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: kBrandColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.receipt_long_rounded,
                              size: 64, color: kBrandColor.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _filterStatus == null
                              ? 'No invoices found'
                              : 'No ${_filterStatus.toString().split('.').last} invoices',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to create one',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                  itemCount: invoices.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final doc = invoices[index];
                    return _buildInvoiceCard(doc);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateInvoiceScreen(),
            ),
          );
        },
        elevation: 4,
        highlightElevation: 8,
        backgroundColor: kBrandColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Invoice',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final invoiceNumber = data['invoiceNumber'] ?? '';
    final clientData = data['client'] as Map<String, dynamic>?;
    final clientName = clientData?['name'] ?? 'Unknown Client';
    final total = double.parse(data['total']?.toString() ?? '0');
    final issueDate = (data['issueDate'] as String?) != null
        ? DateTime.parse(data['issueDate'])
        : DateTime.now();
    final dueDate = (data['dueDate'] as String?) != null
        ? DateTime.parse(data['dueDate'])
        : DateTime.now();
    final statusStr = data['status'] as String? ?? 'draft';
    final filterStatus = InvoiceFilterStatus.values.firstWhere(
      (e) => e.toString().split('.').last == statusStr,
      orElse: () => InvoiceFilterStatus.draft,
    );

    final fi.InvoiceStatus modelStatus = _mapFilterToModelStatus(filterStatus);

    // Reconstruct Invoice Object - Handle both old and new item formats
    final itemsList = <InvoiceLineItem>[];
    if (data['items'] is List) {
      for (var item in (data['items'] as List)) {
        try {
          final itemMap = item as Map<String, dynamic>;

          // Handle new format: items saved with flattened structure
          final serviceName = itemMap['serviceName'] ?? itemMap['name'] ?? '';
          final description = itemMap['description'] ?? '';
          final rate = double.parse(itemMap['rate']?.toString() ?? '0');
          final unit = itemMap['unit'] ?? 'hour';
          final quantity = double.parse(itemMap['quantity']?.toString() ?? '0');
          final notes = itemMap['notes']?.toString();

          if (serviceName.isNotEmpty) {
            final service = Service(
              id: itemMap['serviceId']?.toString() ?? '',
              name: serviceName,
              description: description,
              rate: rate,
              unit: unit,
            );
            itemsList.add(InvoiceLineItem(
              service: service,
              quantity: quantity,
              notes: notes,
            ));
          }
        } catch (e) {
          // Skip invalid items
          continue;
        }
      }
    }

    final invoice = fi.FreelanceInvoice(
      id: doc.id,
      invoiceNumber: invoiceNumber,
      client: Client(
        id: 'unknown',
        name: clientName,
        email: clientData?['email'] ?? '',
        phone: clientData?['phone'] ?? '',
        address: clientData?['address'] ?? '',
        company: clientData?['company'],
      ),
      issueDate: issueDate,
      dueDate: dueDate,
      items: itemsList,
      status: modelStatus,
      taxRate: double.parse(data['taxRate']?.toString() ?? '0'),
      notes: data['notes'],
      termsAndConditions: data['termsAndConditions'],
    );

    final isOverdue = modelStatus != fi.InvoiceStatus.paid &&
        modelStatus != fi.InvoiceStatus.cancelled &&
        dueDate.isBefore(DateTime.now());

    final statusColor = isOverdue ? Colors.red : _getStatusColor(filterStatus);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Navigate to details if implemented
            },
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status Color Strip
                      Container(
                        width: 6,
                        color: statusColor,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Invoice # and Status Badge
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    invoiceNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: statusColor.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isOverdue
                                              ? Icons.warning_rounded
                                              : _getStatusIcon(filterStatus),
                                          size: 14,
                                          color: statusColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isOverdue
                                              ? 'OVERDUE'
                                              : statusStr.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Client Name
                              Text(
                                clientName,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Amount and Date
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'TOTAL AMOUNT',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Rs ${total.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: kBrandColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Due: ${DateFormat.yMMMd().format(dueDate)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isOverdue
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isOverdue
                                              ? Colors.red
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                Divider(height: 1, color: Colors.grey[100]),

                // Actions Toolbar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: Colors.grey[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.edit_note_rounded,
                        label: 'Status',
                        color: Colors.grey.shade700,
                        onTap: () => _showStatusDialog(doc.id, filterStatus),
                      ),
                      _buildVerticalDivider(),
                      _buildActionButton(
                        icon: Icons.picture_as_pdf_rounded,
                        label: 'PDF',
                        color: kBrandColor,
                        onTap: () async {
                          try {
                            if (context.mounted) {
                              await PdfService.generateAndPrintInvoice(
                                invoice,
                                invoice.client,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error generating PDF: $e')),
                              );
                            }
                          }
                        },
                      ),
                      _buildVerticalDivider(),
                      _buildActionButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete',
                        color: AppColors.error,
                        onTap: () => _deleteInvoice(doc.id),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 20,
      width: 1,
      color: Colors.grey[300],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
