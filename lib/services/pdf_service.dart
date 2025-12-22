import 'package:gsheet/models/freelance_invoice.dart';
import 'package:gsheet/models/client.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  // Brand Colors
  static const PdfColor _brandColor = PdfColor.fromInt(0xFF5170FF);
  static const PdfColor _accentColor = PdfColor.fromInt(0xFFF5F7FA);
  static const PdfColor _textColor = PdfColor.fromInt(0xFF333333);
  static const PdfColor _lightTextColor = PdfColor.fromInt(0xFF666666);

  static Future<void> generateAndPrintInvoice(
    FreelanceInvoice invoice,
    Client client,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero, // Zero margin to allow full-width header
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Top Brand Bar
              pw.Container(
                height: 10,
                width: double.infinity,
                color: _brandColor,
              ),

              // 2. Main Content Container
              pw.Padding(
                padding: const pw.EdgeInsets.all(40),
                child: pw.Column(
                  children: [
                    // Header Section
                    _buildHeader(invoice, dateFormat),
                    pw.SizedBox(height: 40),

                    // Client & Vendor Info
                    _buildAddresses(client),
                    pw.SizedBox(height: 40),

                    // Items Table
                    _buildItemsTable(invoice),
                    pw.SizedBox(height: 20),

                    // Totals
                    _buildTotals(invoice),
                    pw.SizedBox(height: 40),

                    // Footer (Notes & Terms)
                    _buildFooter(invoice),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  static pw.Widget _buildHeader(
      FreelanceInvoice invoice, DateFormat dateFormat) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo Placeholder (Text for now)
            pw.Text(
              'INVOICO',
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: _brandColor,
                letterSpacing: 1.5,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Professional Invoice',
              style: const pw.TextStyle(
                fontSize: 10,
                color: _lightTextColor,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: _textColor,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildInfoRow('Invoice #', invoice.invoiceNumber),
            _buildInfoRow('Date', dateFormat.format(invoice.issueDate)),
            _buildInfoRow('Due Date', dateFormat.format(invoice.dueDate)),
            pw.SizedBox(height: 5),
            // Status Badge
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                color: invoice.status == InvoiceStatus.paid
                    ? PdfColors.green100
                    : invoice.status == InvoiceStatus.overdue
                        ? PdfColors.red100
                        : PdfColors.grey200,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                invoice.status.toString().split('.').last.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: invoice.status == InvoiceStatus.paid
                      ? PdfColors.green700
                      : invoice.status == InvoiceStatus.overdue
                          ? PdfColors.red700
                          : PdfColors.grey700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            '$label:  ',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _lightTextColor,
            ),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 10, color: _textColor),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAddresses(Client client) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Bill To
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BILL TO',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _lightTextColor,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                client.name,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _textColor,
                ),
              ),
              if (client.company != null)
                pw.Text(client.company!,
                    style: const pw.TextStyle(fontSize: 10)),
              pw.Text(client.email, style: const pw.TextStyle(fontSize: 10)),
              pw.Text(client.phone, style: const pw.TextStyle(fontSize: 10)),
              pw.Text(client.address, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        // From (Your Business)
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'FROM',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _lightTextColor,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Your Company Name', // Replace with dynamic data if available
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _textColor,
                ),
              ),
              pw.Text('professional@email.com',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text('+123 456 7890', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Business Address Here',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(FreelanceInvoice invoice) {
    return pw.TableHelper.fromTextArray(
      headerDecoration: const pw.BoxDecoration(color: _brandColor),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _accentColor, width: 1),
        ),
      ),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      headers: ['Description', 'Qty', 'Rate', 'Amount'],
      data: invoice.items.map((item) {
        return [
          item.service.name,
          item.quantity.toString(),
          'Rs ${item.service.rate.toStringAsFixed(2)}',
          'Rs ${item.totalPrice.toStringAsFixed(2)}',
        ];
      }).toList(),
    );
  }

  static pw.Widget _buildTotals(FreelanceInvoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 200,
          child: pw.Column(
            children: [
              _buildTotalRow('Subtotal', invoice.subtotal),
              _buildTotalRow('Tax (${invoice.taxRate.toStringAsFixed(0)}%)',
                  invoice.taxAmount),
              pw.Divider(color: _accentColor),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: _brandColor,
                    ),
                  ),
                  pw.Text(
                    'Rs ${invoice.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: _brandColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 10,
              color: _lightTextColor,
            ),
          ),
          pw.Text(
            'Rs ${amount.toStringAsFixed(2)}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(FreelanceInvoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (invoice.notes != null && invoice.notes!.isNotEmpty)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Notes',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _lightTextColor,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  invoice.notes!,
                  style:
                      const pw.TextStyle(fontSize: 9, color: _lightTextColor),
                ),
              ],
            ),
          ),
        pw.SizedBox(width: 20),
        if (invoice.termsAndConditions != null &&
            invoice.termsAndConditions!.isNotEmpty)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Terms & Conditions',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _lightTextColor,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  invoice.termsAndConditions!,
                  style:
                      const pw.TextStyle(fontSize: 9, color: _lightTextColor),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
