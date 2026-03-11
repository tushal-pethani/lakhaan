import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import '../storage/app_data_store.dart';
import 'invoice_theme_renderer.dart';

class PublicInvoiceScreen extends StatefulWidget {
  final String userId;
  final String invoiceId;

  const PublicInvoiceScreen({super.key, required this.userId, required this.invoiceId});

  @override
  State<PublicInvoiceScreen> createState() => _PublicInvoiceScreenState();
}

class _PublicInvoiceScreenState extends State<PublicInvoiceScreen> {
  bool _loading = true;
  String? _error;
  InvoicePrintData? _printData;

  @override
  void initState() {
    super.initState();
    _fetchInvoiceData();
  }

  Future<void> _fetchInvoiceData() async {
    try {
      // Fetch Invoice Directly using userId
      final invoiceDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('invoices')
          .doc(widget.invoiceId)
          .get();

      if (!invoiceDoc.exists) {
        setState(() {
          _error = 'Invoice not found or link is invalid.';
          _loading = false;
        });
        return;
      }

      final invoiceData = invoiceDoc.data();
      if (invoiceData == null) {
        setState(() {
          _error = 'Invoice data is invalid.';
          _loading = false;
        });
        return;
      }
      
      final userId = widget.userId;
      final clientId = invoiceData['clientId'] as String;

      // Fetch Client Data
      final clientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('clients')
          .doc(clientId)
          .get();
          
      final clientData = clientDoc.data();
      
      // Fetch Profile Data
      final profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('data')
          .get();
          
      final profileData = profileDoc.data();

      if (clientData == null) {
        setState(() {
          _error = 'Client data missing for this invoice.';
          _loading = false;
        });
        return;
      }

      // Build Print Data
      final itemsList = (invoiceData['items'] as List<dynamic>?) ?? [];
      final items = itemsList.map((e) {
        final map = e as Map<String, dynamic>;
        final qty = (map['quantity'] as num).toInt();
        final rate = (map['rate'] as num).toDouble();
        final discount = (map['discount'] as num?)?.toDouble() ?? 0.0;
        final tax = (map['tax'] as num?)?.toDouble() ?? 0.0;
        return InvoicePrintItem(
          description: map['description'] as String,
          quantity: qty,
          unit: map['unit'] as String? ?? 'pcs',
          rate: rate,
          discount: discount,
          tax: tax,
          amount: (qty * rate) - discount + tax,
        );
      }).toList();

      final subtotal = items.fold<double>(0, (sum, item) => sum + (item.quantity * item.rate));
      final discount = items.fold<double>(0, (sum, item) => sum + (item.discount ?? 0));
      final itemTax = items.fold<double>(0, (sum, item) => sum + (item.tax ?? 0));
      final cgstRate = (invoiceData['cgstRate'] as num?)?.toDouble() ?? 0.0;
      final sgstRate = (invoiceData['sgstRate'] as num?)?.toDouble() ?? 0.0;
      final igstRate = (invoiceData['igstRate'] as num?)?.toDouble() ?? 0.0;
      
      final subtotalAfterDiscountAndTax = subtotal - discount + itemTax;
      final cgstAmount = subtotalAfterDiscountAndTax * cgstRate / 100;
      final sgstAmount = subtotalAfterDiscountAndTax * sgstRate / 100;
      final igstAmount = subtotalAfterDiscountAndTax * igstRate / 100;
      
      final totalAmount = (invoiceData['totalAmount'] as num).toDouble();
      
      final roundOff = (totalAmount - (subtotalAfterDiscountAndTax + cgstAmount + sgstAmount + igstAmount)).roundToDouble();

      final companyName = (profileData?['businessName'] as String?)?.isNotEmpty == true
          ? profileData!['businessName'] as String
          : ((profileData?['name'] as String?)?.isNotEmpty == true ? profileData!['name'] as String : 'Your Company');

      final companyAddress = (profileData?['address'] as String?)?.isNotEmpty == true
          ? profileData!['address'] as String
          : 'Address';
      final companyCity = (profileData?['city'] as String?)?.isNotEmpty == true
          ? profileData!['city'] as String
          : 'City';
      final companyGst = (profileData?['gstNumber'] as String?)?.isNotEmpty == true
          ? profileData!['gstNumber'] as String
          : 'GSTIN';
      final companyPhone = (profileData?['phone'] as String?)?.isNotEmpty == true
          ? profileData!['phone'] as String
          : '';
      final companyEmail = (profileData?['email'] as String?)?.isNotEmpty == true
          ? profileData!['email'] as String
          : '';

      final printData = InvoicePrintData(
        billNo: invoiceData['billNo'] as String,
        date: DateTime.parse(invoiceData['date'] as String),
        client: InvoicePrintClient(
          name: clientData['name'] as String? ?? 'Unknown',
          address: clientData['address'] as String? ?? '',
          city: clientData['city'] as String? ?? '',
          state: clientData['state'] as String? ?? '',
          pincode: clientData['pincode'] as String? ?? '',
          gstNumber: clientData['gstNumber'] as String? ?? '',
          panNumber: clientData['panNumber'] as String?,
          phone: clientData['phone'] as String? ?? '',
        ),
        company: InvoicePrintCompany(
          name: companyName,
          address: companyAddress,
          city: companyCity,
          gstNumber: companyGst,
          panNumber: profileData?['panNumber'] as String?,
          contact: companyPhone,
          bankName: profileData?['bankName'] as String?,
          accountNumber: profileData?['accountNumber'] as String?,
          ifscCode: profileData?['ifscCode'] as String?,
        ),
        items: items,
        subtotal: subtotal,
        discount: discount,
        cgstRate: cgstRate,
        cgstAmount: cgstAmount,
        sgstRate: sgstRate,
        sgstAmount: sgstAmount,
        igstRate: igstRate,
        igstAmount: igstAmount,
        roundOff: roundOff,
        totalAmount: totalAmount,
        totalQty: items.fold<int>(0, (sum, item) => sum + item.quantity),
        theme: invoiceData['theme'] as String? ?? 'modern',
        chNo: invoiceData['chNo'] as String?,
        termsAndConditions: invoiceData['termsAndConditions'] as String?,
      );

      setState(() {
        _printData = printData;
        _loading = false;
      });
      
    } catch (e) {
      setState(() {
        _error = 'Failed to load invoice. Please try again later.';
        _loading = false;
      });
      debugPrint('Error fetching public invoice: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _printData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Unknown error',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Standard Scaffold with a PDF preview and download options
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${_printData!.billNo}'),
        centerTitle: true,
      ),
      body: PdfPreview(
        build: (format) => InvoiceThemeRenderer.buildPdf(_printData!),
        allowSharing: true,
        allowPrinting: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}
