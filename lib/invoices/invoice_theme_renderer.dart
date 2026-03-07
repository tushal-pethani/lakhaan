import 'dart:typed_data';
import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoicePrintItem {
  final String description;
  final int quantity;
  final String unit;
  final double rate;
  final double discount;
  final double tax;
  final double amount;

  InvoicePrintItem({
    required this.description,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.discount,
    required this.tax,
    required this.amount,
  });
}

class InvoicePrintClient {
  final String name;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String gstNumber;
  final String? panNumber;
  final String phone;

  InvoicePrintClient({
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.gstNumber,
    this.panNumber,
    required this.phone,
  });
}

class InvoicePrintCompany {
  final String name;
  final String address;
  final String city;
  final String gstNumber;
  final String? panNumber;
  final String contact;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final Uint8List? logo;

  InvoicePrintCompany({
    required this.name,
    required this.address,
    required this.city,
    required this.gstNumber,
    this.panNumber,
    required this.contact,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.logo,
  });
}

class InvoicePrintData {
  final String billNo;
  final DateTime date;
  final String? chNo;
  final String theme;
  final List<InvoicePrintItem> items;
  final double subtotal;
  final double discount;
  final double cgstRate;
  final double cgstAmount;
  final double sgstRate;
  final double sgstAmount;
  final double igstRate;
  final double igstAmount;
  final double roundOff;
  final double totalAmount;
  final int totalQty;
  final InvoicePrintClient client;
  final InvoicePrintCompany company;
  final String? termsAndConditions;

  InvoicePrintData({
    required this.billNo,
    required this.date,
    this.chNo,
    required this.theme,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.cgstRate,
    required this.cgstAmount,
    required this.sgstRate,
    required this.sgstAmount,
    required this.igstRate,
    required this.igstAmount,
    required this.roundOff,
    required this.totalAmount,
    required this.totalQty,
    required this.client,
    required this.company,
    this.termsAndConditions,
  });
}

String _numberToWords(int number) {
  if (number == 0) return 'Zero';
  final ones = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];
  final tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];
  final thousands = ['', 'Thousand', 'Lakh', 'Crore'];

  if (number < 20) return ones[number];
  if (number < 100)
    return '${tens[number ~/ 10]}${number % 10 != 0 ? ' ${ones[number % 10]}' : ''}';

  String result = '';
  int temp = number;
  int group = 0;

  while (temp > 0) {
    if (temp % 1000 != 0) {
      int n = temp % 1000;
      String s = '';
      if (n >= 100) {
        s = '${ones[n ~/ 100]} Hundred';
        n = n % 100;
      }
      if (n > 0) {
        if (n < 20) {
          s += '${s.isNotEmpty ? ' ' : ''}${ones[n]}';
        } else {
          s +=
              '${s.isNotEmpty ? ' ' : ''}${tens[n ~/ 10]}${n % 10 != 0 ? ' ${ones[n % 10]}' : ''}';
        }
      }
      result = '$s ${thousands[group]}${result.isNotEmpty ? ' $result' : ''}';
    }
    temp ~/= 1000;
    group++;
  }
  return result.trim();
}

class _ThemeColors {
  final PdfColor headerBg;
  final PdfColor headerText;
  final PdfColor tableHeaderBg;
  final PdfColor tableHeaderText;
  final PdfColor accent;
  final PdfColor border;

  const _ThemeColors({
    required this.headerBg,
    required this.headerText,
    required this.tableHeaderBg,
    required this.tableHeaderText,
    required this.accent,
    required this.border,
  });
}

const Map<String, _ThemeColors> _themes = {
  'classic': _ThemeColors(
    headerBg: PdfColor.fromInt(0xFF2563EB),
    headerText: PdfColor.fromInt(0xFFFFFFFF),
    tableHeaderBg: PdfColor.fromInt(0xFF2563EB),
    tableHeaderText: PdfColor.fromInt(0xFFFFFFFF),
    accent: PdfColor.fromInt(0xFF2563EB),
    border: PdfColor.fromInt(0xFF2563EB),
  ),
  'modern': _ThemeColors(
    headerBg: PdfColor.fromInt(0xFF059669),
    headerText: PdfColor.fromInt(0xFFFFFFFF),
    tableHeaderBg: PdfColor.fromInt(0xFF059669),
    tableHeaderText: PdfColor.fromInt(0xFFFFFFFF),
    accent: PdfColor.fromInt(0xFF059669),
    border: PdfColor.fromInt(0xFF059669),
  ),
  'professional': _ThemeColors(
    headerBg: PdfColor.fromInt(0xFF1F2937),
    headerText: PdfColor.fromInt(0xFFFFFFFF),
    tableHeaderBg: PdfColor.fromInt(0xFF374151),
    tableHeaderText: PdfColor.fromInt(0xFFFFFFFF),
    accent: PdfColor.fromInt(0xFF1F2937),
    border: PdfColor.fromInt(0xFF374151),
  ),
  'plain': _ThemeColors(
    headerBg: PdfColor.fromInt(0xFFF3F4F6),
    headerText: PdfColor.fromInt(0xFF1F2937),
    tableHeaderBg: PdfColor.fromInt(0xFFE5E7EB),
    tableHeaderText: PdfColor.fromInt(0xFF1F2937),
    accent: PdfColor.fromInt(0xFF1F2937),
    border: PdfColor.fromInt(0xFFD1D5DB),
  ),
  'royal': _ThemeColors(
    headerBg: PdfColor.fromInt(0xFF7C3AED),
    headerText: PdfColor.fromInt(0xFFFFFFFF),
    tableHeaderBg: PdfColor.fromInt(0xFF7C3AED),
    tableHeaderText: PdfColor.fromInt(0xFFFFFFFF),
    accent: PdfColor.fromInt(0xFF7C3AED),
    border: PdfColor.fromInt(0xFF7C3AED),
  ),
  'sunset': _ThemeColors(
    headerBg: PdfColor.fromInt(0xFFEA580C),
    headerText: PdfColor.fromInt(0xFFFFFFFF),
    tableHeaderBg: PdfColor.fromInt(0xFFEA580C),
    tableHeaderText: PdfColor.fromInt(0xFFFFFFFF),
    accent: PdfColor.fromInt(0xFFEA580C),
    border: PdfColor.fromInt(0xFFEA580C),
  ),
  'ocean': _ThemeColors(
    headerBg: PdfColor.fromInt(0xFF0891B2),
    headerText: PdfColor.fromInt(0xFFFFFFFF),
    tableHeaderBg: PdfColor.fromInt(0xFF0891B2),
    tableHeaderText: PdfColor.fromInt(0xFFFFFFFF),
    accent: PdfColor.fromInt(0xFF0891B2),
    border: PdfColor.fromInt(0xFF0891B2),
  ),
  'ruby': _ThemeColors(
    headerBg: PdfColor.fromInt(0xFFDC2626),
    headerText: PdfColor.fromInt(0xFFFFFFFF),
    tableHeaderBg: PdfColor.fromInt(0xFFDC2626),
    tableHeaderText: PdfColor.fromInt(0xFFFFFFFF),
    accent: PdfColor.fromInt(0xFFDC2626),
    border: PdfColor.fromInt(0xFFDC2626),
  ),
};

class InvoiceThemeRenderer {
  static String _formatCurrency(double amount) => amount.toStringAsFixed(2);

  static pw.Widget _buildHeader(
    InvoicePrintData data,
    _ThemeColors themeColors,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: themeColors.headerBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (data.company.logo != null)
            pw.Container(
              width: 60,
              height: 60,
              margin: const pw.EdgeInsets.only(right: 16),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(4),
                color: PdfColors.white,
              ),
              child: pw.Image(
                pw.MemoryImage(data.company.logo!),
                fit: pw.BoxFit.contain,
              ),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  data.company.name,
                  style: pw.TextStyle(
                    color: themeColors.headerText,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${data.company.address}, ${data.company.city}',
                  style: pw.TextStyle(
                    color: themeColors.headerText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'GST: ${data.company.gstNumber}',
                style: pw.TextStyle(
                  color: themeColors.headerText,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (data.company.panNumber != null &&
                  data.company.panNumber!.isNotEmpty)
                pw.Text(
                  'PAN: ${data.company.panNumber}',
                  style: pw.TextStyle(
                    color: themeColors.headerText,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // InvoiceThemeRenderer class starts above - fix the class brace issue
  static pw.Widget _buildTable(
    InvoicePrintData data,
    _ThemeColors themeColors,
  ) {
    return pw.Table(
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(),
        2: const pw.FixedColumnWidth(40),
        3: const pw.FixedColumnWidth(50),
        4: const pw.FixedColumnWidth(60),
        5: const pw.FixedColumnWidth(55),
        6: const pw.FixedColumnWidth(55),
        7: const pw.FixedColumnWidth(70),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: themeColors.tableHeaderBg),
          children: [
            _tableCell(
              '#',
              themeColors.tableHeaderText,
              pw.TextAlign.center,
              border: pw.Border(
                left: pw.BorderSide(color: themeColors.border, width: 0.5),
                top: pw.BorderSide(color: themeColors.border, width: 0.5),
                bottom: pw.BorderSide(color: themeColors.border, width: 0.5),
              ),
            ),
            _tableCell(
              'Item',
              themeColors.tableHeaderText,
              pw.TextAlign.left,
              border: pw.Border(
                top: pw.BorderSide(color: themeColors.border, width: 0.5),
                bottom: pw.BorderSide(color: themeColors.border, width: 0.5),
              ),
            ),
            _tableCell(
              'Qty',
              themeColors.tableHeaderText,
              pw.TextAlign.center,
              border: pw.Border(
                top: pw.BorderSide(color: themeColors.border, width: 0.5),
                bottom: pw.BorderSide(color: themeColors.border, width: 0.5),
              ),
            ),
            _tableCell(
              'Unit',
              themeColors.tableHeaderText,
              pw.TextAlign.center,
              border: pw.Border(
                top: pw.BorderSide(color: themeColors.border, width: 0.5),
                bottom: pw.BorderSide(color: themeColors.border, width: 0.5),
              ),
            ),
            _tableCell(
              'Rate',
              themeColors.tableHeaderText,
              pw.TextAlign.right,
              border: pw.Border(
                top: pw.BorderSide(color: themeColors.border, width: 0.5),
                bottom: pw.BorderSide(color: themeColors.border, width: 0.5),
              ),
            ),
            _tableCell(
              'Disc.',
              themeColors.tableHeaderText,
              pw.TextAlign.right,
              border: pw.Border(
                top: pw.BorderSide(color: themeColors.border, width: 0.5),
                bottom: pw.BorderSide(color: themeColors.border, width: 0.5),
              ),
            ),
            _tableCell(
              'Tax',
              themeColors.tableHeaderText,
              pw.TextAlign.right,
              border: pw.Border(
                top: pw.BorderSide(color: themeColors.border, width: 0.5),
                bottom: pw.BorderSide(color: themeColors.border, width: 0.5),
              ),
            ),
            _tableCell(
              'Amount',
              themeColors.tableHeaderText,
              pw.TextAlign.right,
              border: pw.Border(
                right: pw.BorderSide(color: themeColors.border, width: 0.5),
                top: pw.BorderSide(color: themeColors.border, width: 0.5),
                bottom: pw.BorderSide(color: themeColors.border, width: 0.5),
              ),
            ),
          ],
        ),
        ...List.generate(19, (index) {
          final hasItem = index < data.items.length;
          final item = hasItem ? data.items[index] : null;
          final bottomBorder = hasItem
              ? pw.BorderSide(color: themeColors.border, width: 0.5)
              : pw.BorderSide(color: PdfColors.white, width: 0.0);
          final verticalBorder = pw.Border(
            left: pw.BorderSide(color: themeColors.border, width: 0.5),
            right: pw.BorderSide(color: themeColors.border, width: 0.5),
            bottom: bottomBorder,
          );
          return pw.TableRow(
            children: [
              _tableCell(
                hasItem ? '${index + 1}' : '',
                PdfColors.black,
                pw.TextAlign.center,
                border: verticalBorder,
              ),
              _tableCell(
                item?.description ?? '',
                PdfColors.black,
                pw.TextAlign.left,
                border: verticalBorder,
              ),
              _tableCell(
                hasItem ? '${item!.quantity}' : '',
                PdfColors.black,
                pw.TextAlign.center,
                border: verticalBorder,
              ),
              _tableCell(
                item?.unit ?? '',
                PdfColors.black,
                pw.TextAlign.center,
                border: verticalBorder,
              ),
              _tableCell(
                hasItem ? _formatCurrency(item!.rate) : '',
                PdfColors.black,
                pw.TextAlign.right,
                border: verticalBorder,
              ),
              _tableCell(
                hasItem ? _formatCurrency(item!.discount) : '',
                PdfColors.black,
                pw.TextAlign.right,
                border: verticalBorder,
              ),
              _tableCell(
                hasItem ? _formatCurrency(item!.tax) : '',
                PdfColors.black,
                pw.TextAlign.right,
                border: verticalBorder,
              ),
              _tableCell(
                hasItem ? _formatCurrency(item!.amount) : '',
                PdfColors.black,
                pw.TextAlign.right,
                border: verticalBorder,
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableCell(
    String text,
    PdfColor color,
    pw.TextAlign align, {
    pw.Border? border,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      height: 20,
      alignment: align == pw.TextAlign.left
          ? pw.Alignment.centerLeft
          : align == pw.TextAlign.right
          ? pw.Alignment.centerRight
          : pw.Alignment.center,
      decoration: border != null ? pw.BoxDecoration(border: border) : null,
      child: pw.Text(text, style: pw.TextStyle(fontSize: 9, color: color)),
    );
  }

  static pw.Widget _buildTotalsSection(
    InvoicePrintData data,
    _ThemeColors themeColors,
  ) {
    final netPayableWords = _numberToWords(data.totalAmount.floor());
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: themeColors.border, width: 0.5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Net Payable in Words',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  netPayableWords.isNotEmpty
                      ? 'Rupees $netPayableWords Only'
                      : 'Zero Only',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Bank Details',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                pw.SizedBox(height: 4),
                if (data.company.bankName != null &&
                    data.company.bankName!.isNotEmpty)
                  pw.Text(
                    'Bank: ${data.company.bankName}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                if (data.company.accountNumber != null &&
                    data.company.accountNumber!.isNotEmpty)
                  pw.Text(
                    'A/C: ${data.company.accountNumber}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                if (data.company.ifscCode != null &&
                    data.company.ifscCode!.isNotEmpty)
                  pw.Text(
                    'IFSC: ${data.company.ifscCode}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Container(
            width: 180,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Basic Amount',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Rs. ${_formatCurrency(data.subtotal)}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      'Rs. -${_formatCurrency(data.discount)}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                if (data.cgstRate > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'CGST (${data.cgstRate.toStringAsFixed(1)}%)',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'Rs. ${_formatCurrency(data.cgstAmount)}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                if (data.sgstRate > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'SGST (${data.sgstRate.toStringAsFixed(1)}%)',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'Rs. ${_formatCurrency(data.sgstAmount)}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                if (data.igstRate > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'IGST (${data.igstRate.toStringAsFixed(1)}%)',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'Rs. ${_formatCurrency(data.igstAmount)}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Round off',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Rs. ${_formatCurrency(data.roundOff)}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.Divider(color: themeColors.border),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Net Payable',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    pw.Text(
                      'Rs. ${_formatCurrency(data.totalAmount)}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                        color: themeColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceDetails(
    InvoicePrintData data,
    _ThemeColors themeColors,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: themeColors.border, width: 0.5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Bill To',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  data.client.name,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  data.client.address,
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  '${data.client.city}, ${data.client.state} - ${data.client.pincode}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'GST: ${data.client.gstNumber}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                if (data.client.panNumber != null &&
                    data.client.panNumber!.isNotEmpty)
                  pw.Text(
                    'PAN: ${data.client.panNumber}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                pw.Text(
                  'Ph: ${data.client.phone}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Invoice No: ',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    data.billNo,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Date: ', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    '${data.date.day.toString().padLeft(2, '0')}-${data.date.month.toString().padLeft(2, '0')}-${data.date.year}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              if (data.chNo != null && data.chNo!.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('CH No: ', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      data.chNo!,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(
    InvoicePrintData data,
    _ThemeColors themeColors,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: themeColors.border, width: 0.5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Terms and Conditions',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  data.termsAndConditions ?? 'No terms and conditions',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Receiver's Signature",
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 25),
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(width: 0.5)),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Authorised Signature',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 25),
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(width: 0.5)),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  data.company.name,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalQtySection(
    InvoicePrintData data,
    _ThemeColors themeColors,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: themeColors.border, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.start,
        children: [
          pw.Text(
            'Total Qty: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.Text(
            '${data.totalQty}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
        ],
      ),
    );
  }

  static Future<Uint8List> buildPdf(InvoicePrintData data) async {
    final pdf = pw.Document();
    final themeColors = _themes[data.theme] ?? _themes['classic']!;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: themeColors.border, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildHeader(data, themeColors),
                _buildInvoiceDetails(data, themeColors),
                _buildTable(data, themeColors),
                _buildTotalQtySection(data, themeColors),
                _buildTotalsSection(data, themeColors),
                _buildFooter(data, themeColors),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
