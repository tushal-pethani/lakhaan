import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../invoices/create_invoice_form.dart';
import '../invoices/invoice_preview_screen.dart';
import '../invoices/invoice_theme_renderer.dart';
import '../navbar/navbar.dart';
import '../services/firestore_service.dart';
import '../storage/app_data_store.dart';

/// Simple models to mirror your React types.
/// Replace / extend with your real models.
class Invoice {
  final String id;
  String billNo;
  String clientId;
  DateTime date;
  double totalAmount;
  String status; // 'draft' | 'sent' | 'paid'
  List<InvoiceFormItem>? items;
  double? cgstRate;
  double? sgstRate;
  double? igstRate;
  String? theme;
  String? chNo;
  String? termsAndConditions;

  Invoice({
    required this.id,
    required this.billNo,
    required this.clientId,
    required this.date,
    required this.totalAmount,
    required this.status,
    this.items,
    this.cgstRate,
    this.sgstRate,
    this.igstRate,
    this.theme,
    this.chNo,
    this.termsAndConditions,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Invoice> _invoices = [];

  String _search = '';
  String _statusFilter = 'all'; // 'all' | 'draft' | 'sent' | 'paid'
  String _sortBy =
      'date-desc'; // same keys as React: date-asc, amount-desc, etc.

  StoredClient? _getClient(String id) {
    for (final c in AppDataStore.instance.clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _loadInvoicesFromFirestore();
    } else {
      _loadInvoicesFromStore();
    }
  }

  Future<void> _loadInvoicesFromFirestore() async {
    final invoices = await FirestoreService.instance.getInvoices();
    final clients = await FirestoreService.instance.getClients();
    
    // Populate AppDataStore clients for lookup in buildPrintData
    AppDataStore.instance.clients = clients.map((c) => StoredClient(
      id: c['id'] as String,
      name: c['name'] as String? ?? '',
      gstNumber: c['gstNumber'] as String? ?? '',
      panNumber: c['panNumber'] as String? ?? '',
      address: c['address'] as String? ?? '',
      city: c['city'] as String? ?? '',
      state: c['state'] as String? ?? '',
      pincode: c['pincode'] as String? ?? '',
      phone: c['phone'] as String? ?? '',
      email: c['email'] as String? ?? '',
    )).toList();

    setState(() {
      _invoices.clear();
      _invoices.addAll(invoices.map((inv) {
        final items = (inv['items'] as List<dynamic>?)?.map((item) => InvoiceFormItem(
          description: item['description'] as String? ?? '',
          quantity: item['quantity'] as int? ?? 0,
          unit: item['unit'] as String? ?? 'pcs',
          rate: (item['rate'] as num?)?.toDouble() ?? 0,
          discount: (item['discount'] as num?)?.toDouble() ?? 0,
          tax: (item['tax'] as num?)?.toDouble() ?? 0,
        )).toList();
        
        return Invoice(
          id: inv['id'] as String,
          billNo: inv['billNo'] as String? ?? '',
          clientId: inv['clientId'] as String? ?? '',
          date: DateTime.tryParse(inv['date'] as String? ?? '') ?? DateTime.now(),
          totalAmount: (inv['totalAmount'] as num?)?.toDouble() ?? 0,
          status: inv['status'] as String? ?? 'draft',
          theme: inv['theme'] as String?,
          chNo: inv['chNo'] as String?,
          termsAndConditions: inv['termsAndConditions'] as String?,
          items: items,
          cgstRate: (inv['cgstRate'] as num?)?.toDouble(),
          sgstRate: (inv['sgstRate'] as num?)?.toDouble(),
          igstRate: (inv['igstRate'] as num?)?.toDouble(),
        );
      }));
    });
  }

  void _loadInvoicesFromStore() {
    final stored = AppDataStore.instance.invoices;
    if (stored.isEmpty) return;
    setState(() {
      _invoices.clear();
      _invoices.addAll(
        stored.map(
          (s) => Invoice(
            id: s.id,
            billNo: s.billNo,
            clientId: s.clientId,
            date: DateTime.tryParse(s.dateIso) ?? DateTime.now(),
            totalAmount: s.totalAmount,
            status: s.status,
            theme: s.theme,
            chNo: s.chNo,
            termsAndConditions: s.termsAndConditions,
            items: s.items
                ?.map(
                  (item) => InvoiceFormItem(
                    description: item.description,
                    quantity: item.quantity,
                    unit: item.unit ?? 'pcs',
                    rate: item.rate,
                    discount: item.discount ?? 0,
                    tax: item.tax ?? 0,
                  ),
                )
                .toList(),
            cgstRate: s.cgstRate,
            sgstRate: s.sgstRate,
            igstRate: s.igstRate,
          ),
        ),
      );
    });
  }

  Future<void> _persistInvoices() async {
    if (kIsWeb) {
      for (final inv in _invoices) {
        await FirestoreService.instance.updateInvoice(inv.id, {
          'billNo': inv.billNo,
          'clientId': inv.clientId,
          'date': inv.date.toIso8601String(),
          'totalAmount': inv.totalAmount,
          'status': inv.status,
          'theme': inv.theme,
          'chNo': inv.chNo,
          'termsAndConditions': inv.termsAndConditions,
          'items': inv.items?.map((item) => {
            'description': item.description,
            'quantity': item.quantity,
            'unit': item.unit,
            'rate': item.rate,
            'discount': item.discount,
            'tax': item.tax,
          }).toList(),
          'cgstRate': inv.cgstRate,
          'sgstRate': inv.sgstRate,
          'igstRate': inv.igstRate,
        });
      }
      return;
    }

    AppDataStore.instance.invoices = _invoices
        .map(
          (inv) => StoredInvoice(
            id: inv.id,
            billNo: inv.billNo,
            clientId: inv.clientId,
            dateIso: inv.date.toIso8601String(),
            totalAmount: inv.totalAmount,
            status: inv.status,
            theme: inv.theme,
            chNo: inv.chNo,
            termsAndConditions: inv.termsAndConditions,
            items: inv.items
                ?.map(
                  (item) => StoredInvoiceItem(
                    description: item.description,
                    quantity: item.quantity,
                    unit: item.unit,
                    rate: item.rate,
                    discount: item.discount,
                    tax: item.tax,
                  ),
                )
                .toList(),
            cgstRate: inv.cgstRate,
            sgstRate: inv.sgstRate,
            igstRate: inv.igstRate,
          ),
        )
        .toList();
    await AppDataStore.instance.saveInvoices();
  }

  Future<void> _onLogout() async {
    await FirebaseAuth.instance.signOut();
  }

  void _deleteInvoice(String id) {
    setState(() {
      _invoices.removeWhere((inv) => inv.id == id);
    });
    if (kIsWeb) {
      FirestoreService.instance.deleteInvoice(id);
    } else {
      _persistInvoices();
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invoice deleted')));
  }

  void _updateInvoiceStatus(String id, String newStatus) {
    setState(() {
      final inv = _invoices.firstWhere((i) => i.id == id);
      inv.status = newStatus;
    });
    _persistInvoices();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Status changed to $newStatus')));
  }

  Future<void> _onNewInvoice() async {
    // On web, load clients from Firestore
    final clientsList = kIsWeb 
        ? (await FirestoreService.instance.getClients())
            .map((c) => InvoiceFormClient(id: c['id'] as String, name: c['name'] as String))
            .toList()
        : AppDataStore.instance.clients
            .map((c) => InvoiceFormClient(id: c.id, name: c.name))
            .toList();

    final result = await showInvoiceFormDialog(
      context,
      clients: clientsList,
    );

    if (result == null) return;

    final subtotal = result.items.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final cgstAmount = subtotal * result.cgstRate / 100;
    final sgstAmount = subtotal * result.sgstRate / 100;
    final igstAmount = subtotal * result.igstRate / 100;
    final totalAmount = subtotal + cgstAmount + sgstAmount + igstAmount;

    String invoiceId;
    if (kIsWeb) {
      // Save to Firestore first to get ID
      invoiceId = await FirestoreService.instance.addInvoice({
        'billNo': result.billNo,
        'clientId': result.clientId,
        'date': result.date.toIso8601String(),
        'totalAmount': totalAmount,
        'status': 'draft',
        'items': result.items.map((item) => {
          'description': item.description,
          'quantity': item.quantity,
          'unit': item.unit,
          'rate': item.rate,
          'discount': item.discount,
          'tax': item.tax,
        }).toList(),
        'cgstRate': result.cgstRate,
        'sgstRate': result.sgstRate,
        'igstRate': result.igstRate,
        'theme': result.theme,
        'chNo': result.chNo,
        'termsAndConditions': result.termsAndConditions,
      });
      setState(() {
        _invoices.add(
          Invoice(
            id: invoiceId,
            billNo: result.billNo,
            clientId: result.clientId,
            date: result.date,
            totalAmount: totalAmount,
            status: 'draft',
            items: result.items,
            cgstRate: result.cgstRate,
            sgstRate: result.sgstRate,
            igstRate: result.igstRate,
            theme: result.theme,
            chNo: result.chNo,
            termsAndConditions: result.termsAndConditions,
          ),
        );
      });
      return;
    }

    setState(() {
      _invoices.add(
        Invoice(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          billNo: result.billNo,
          clientId: result.clientId,
          date: result.date,
          totalAmount: totalAmount,
          status: 'draft',
          items: result.items,
          cgstRate: result.cgstRate,
          sgstRate: result.sgstRate,
          igstRate: result.igstRate,
          theme: result.theme,
        ),
      );
    });
    await _persistInvoices();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invoice created')));
  }

  Future<void> _onEditInvoice(Invoice inv) async {
    final result = await showInvoiceFormDialog(
      context,
      clients: AppDataStore.instance.clients
          .map((c) => InvoiceFormClient(id: c.id, name: c.name))
          .toList(),
      initialClientId: inv.clientId,
      initialBillNo: inv.billNo,
      initialDate: inv.date,
      initialChNo: inv.chNo,
      initialItems: inv.items,
      initialCgstRate: inv.cgstRate,
      initialSgstRate: inv.sgstRate,
      initialIgstRate: inv.igstRate,
      initialTheme: inv.theme,
      initialTermsAndConditions: inv.termsAndConditions,
      isEdit: true,
    );

    if (result == null) return;

    final subtotal = result.items.fold<double>(
      0,
      (sum, item) => sum + (item.quantity * item.rate),
    );
    final discount = result.items.fold<double>(
      0,
      (sum, item) => sum + item.discountAmount,
    );
    final itemTax = result.items.fold<double>(
      0,
      (sum, item) => sum + (item.tax ?? 0),
    );
    final cgstAmount = subtotal * result.cgstRate / 100;
    final sgstAmount = subtotal * result.sgstRate / 100;
    final igstAmount = subtotal * result.igstRate / 100;
    final totalAmount =
        subtotal - discount + itemTax + cgstAmount + sgstAmount + igstAmount;

    setState(() {
      inv.billNo = result.billNo;
      inv.clientId = result.clientId;
      inv.date = result.date;
      inv.chNo = result.chNo;
      inv.totalAmount = totalAmount;
      inv.items = result.items;
      inv.cgstRate = result.cgstRate;
      inv.sgstRate = result.sgstRate;
      inv.igstRate = result.igstRate;
      inv.theme = result.theme;
      inv.termsAndConditions = result.termsAndConditions;
    });
    await _persistInvoices();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invoice updated')));
  }

  void _onPreviewInvoice(Invoice inv) {
    final data = _buildPrintData(inv);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 900,
            height: 700,
            child: InvoicePreviewScreen(data: data),
          ),
        );
      },
    );
  }

  InvoicePrintData _buildPrintData(Invoice inv) {
    final client = _getClient(inv.clientId);
    if (client == null) {
      throw Exception('Client not found for invoice ${inv.id}');
    }

    final profile = AppDataStore.instance.profile;

    final items = (inv.items ?? [])
        .map(
          (e) => InvoicePrintItem(
            description: e.description,
            quantity: e.quantity,
            unit: e.unit ?? 'pcs',
            rate: e.rate,
            discount: e.discount ?? 0,
            tax: e.tax ?? 0,
            amount: e.amount,
          ),
        )
        .toList();

    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + (item.quantity * item.rate),
    );
    final discount = items.fold<double>(
      0,
      (sum, item) => sum + (item.discount ?? 0),
    );
    final itemTax = items.fold<double>(0, (sum, item) => sum + (item.tax ?? 0));
    final cgstRate = inv.cgstRate ?? 0;
    final cgstAmount = subtotal * cgstRate / 100;
    final sgstRate = inv.sgstRate ?? 0;
    final sgstAmount = subtotal * sgstRate / 100;
    final igstRate = inv.igstRate ?? 0;
    final igstAmount = subtotal * igstRate / 100;
    final roundOff =
        (inv.totalAmount -
                (subtotal -
                    discount +
                    itemTax +
                    cgstAmount +
                    sgstAmount +
                    igstAmount))
            .roundToDouble();
    final totalQty = items.fold<int>(0, (sum, item) => sum + item.quantity);

    final companyName = (profile?.businessName.isNotEmpty == true)
        ? profile!.businessName
        : (profile?.name.isNotEmpty == true ? profile!.name : 'Your Company');

    final companyAddress = profile?.address.isNotEmpty == true
        ? profile!.address
        : 'Address';
    final companyCity = profile?.city.isNotEmpty == true
        ? profile!.city
        : 'City';
    final companyGst = profile?.gstNumber.isNotEmpty == true
        ? profile!.gstNumber
        : 'GSTIN';
    final companyPan = profile?.panNumber;
    final companyContact = profile?.phone.isNotEmpty == true
        ? profile!.phone
        : 'Contact';

    return InvoicePrintData(
      billNo: inv.billNo,
      date: inv.date,
      chNo: inv.chNo,
      theme: inv.theme ?? 'classic',
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
      totalAmount: inv.totalAmount,
      totalQty: totalQty,
      client: InvoicePrintClient(
        name: client.name,
        address: client.address,
        city: client.city,
        state: client.state,
        pincode: client.pincode,
        gstNumber: client.gstNumber,
        panNumber: client.panNumber,
        phone: client.phone,
      ),
      company: InvoicePrintCompany(
        name: companyName,
        address: companyAddress,
        city: companyCity,
        gstNumber: companyGst,
        panNumber: companyPan,
        contact: companyContact,
        bankName: profile?.bankName,
        accountNumber: profile?.accountNumber,
        ifscCode: profile?.ifscCode,
        logo: profile?.companyLogoBase64 != null
            ? base64Decode(profile!.companyLogoBase64!)
            : null,
        hsnNumber: profile?.hsnNumber,
      ),
      termsAndConditions: inv.termsAndConditions,
    );
  }

  Future<void> _printInvoice(Invoice inv) async {
    final data = _buildPrintData(inv);
    final pdfBytes = await InvoiceThemeRenderer.buildPdf(data);

    final filename = 'invoice-${inv.billNo}.pdf';

    if (kIsWeb) {
      // On web, trigger browser download (and allow print) via printing plugin.
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);
      return;
    }

    // On desktop/mobile, show a "Save As" dialog so the user chooses where
    // to download the PDF, then write the bytes there.
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Invoice',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (outputPath == null) return; // user cancelled

    final file = File(outputPath);
    await file.writeAsBytes(pdfBytes, flush: true);
  }

  Future<void> _shareOnWhatsApp(Invoice inv) async {
    final client = _getClient(inv.clientId);
    if (client == null) return;

    final phone = client.phone.trim();
    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number found for this client. Please add one in the Clients section.'),
        ),
      );
      return;
    }

    // Generate and trigger PDF download first
    final data = _buildPrintData(inv);
    final pdfBytes = await InvoiceThemeRenderer.buildPdf(data);
    final filename = 'invoice-${inv.billNo}.pdf';
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);

    // Clean phone — remove spaces and dashes, add country code if missing
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!cleanPhone.startsWith('+')) {
      cleanPhone = '+91$cleanPhone'; // Default to India
    }

    final profile = AppDataStore.instance.profile;
    final companyName = profile?.businessName.isNotEmpty == true
        ? profile!.businessName
        : (profile?.name ?? 'Our Company');
    final dateStr = '${inv.date.day.toString().padLeft(2, '0')}/${inv.date.month.toString().padLeft(2, '0')}/${inv.date.year}';

    final message = 'Hello ${client.name},\n\n'
        'Please find your invoice details below:\n\n'
        '📄 Invoice No: ${inv.billNo}\n'
        '📅 Date: $dateStr\n'
        '💰 Amount: ₹${inv.totalAmount.toStringAsFixed(2)}\n\n'
        'From: $companyName\n\n'
        'Thank you for your business!';

    final whatsappUrl = Uri.parse(
      'https://wa.me/${cleanPhone.replaceAll('+', '')}?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  List<Invoice> get _filteredInvoices {
    final searchLower = _search.toLowerCase();

    List<Invoice> result = _invoices.where((inv) {
      final client = _getClient(inv.clientId);
      final billMatch = inv.billNo.toLowerCase().contains(searchLower);
      final clientMatch = (client?.name.toLowerCase() ?? '').contains(
        searchLower,
      );
      final matchesSearch = _search.isEmpty ? true : (billMatch || clientMatch);
      final matchesStatus =
          _statusFilter == 'all' || inv.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    result.sort((a, b) {
      switch (_sortBy) {
        case 'date-asc':
          return a.date.compareTo(b.date);
        case 'date-desc':
          return b.date.compareTo(a.date);
        case 'amount-asc':
          return a.totalAmount.compareTo(b.totalAmount);
        case 'amount-desc':
          return b.totalAmount.compareTo(a.totalAmount);
        case 'billno-asc':
          return a.billNo.compareTo(b.billNo);
        case 'billno-desc':
          return b.billNo.compareTo(a.billNo);
        default:
          return 0;
      }
    });

    return result;
  }

  Color _statusBg(String status, ThemeData theme) {
    if (status == 'paid') {
      return Colors.green.withOpacity(0.1);
    } else if (status == 'sent') {
      return theme.colorScheme.primary.withOpacity(0.1);
    }
    return theme.colorScheme.surfaceVariant;
  }

  Color _statusText(String status, ThemeData theme) {
    if (status == 'paid') return Colors.green[800]!;
    if (status == 'sent') return theme.colorScheme.primary;
    return theme.colorScheme.onSurface.withOpacity(0.6);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = AppDataStore.instance.profile;
    final displayName = (profile?.name.isNotEmpty == true
        ? profile!.name
        : 'User');
    final filtered = _filteredInvoices;
    final pendingCount = _invoices.where((i) => i.status != 'paid').length;

    return Scaffold(
      appBar: Navbar(
        onNewInvoice: _onNewInvoice,
        onLogout: _onLogout,
        userName: displayName,
      ),
      drawer: NavbarDrawer(
        onNewInvoice: _onNewInvoice,
        onLogout: _onLogout,
        userName: displayName,
      ),
      body: Container(
        color: theme.colorScheme.background,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dashboard',
                              style: theme.textTheme.headlineSmall!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Welcome back, $displayName',
                              style: theme.textTheme.bodySmall!.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _onNewInvoice,
                        icon: const Icon(Icons.post_add_outlined, size: 18),
                        label: const Text('New Invoice'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      return Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Total Invoices',
                              value: _invoices.length.toString(),
                              icon: Icons.receipt_long,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: isWide ? 0 : 16, width: isWide ? 16 : 0),
                          Expanded(
                            child: _StatCard(
                              label: 'Pending',
                              value: pendingCount.toString(),
                              icon: Icons.pending_actions,
                              color: const Color(0xFFF59E0B), // Amber 500
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Search + Filter + Sort
                  Row(
                    children: [
                      // Search
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              const Positioned(
                                left: 8,
                                child: Icon(Icons.search, size: 20),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 36),
                                child: TextField(
                                  decoration: const InputDecoration(
                                    hintText: 'Search invoices...',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  textAlignVertical: TextAlignVertical.center,
                                  onChanged: (v) {
                                    setState(() => _search = v);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Filter (status)
                      PopupMenuButton<String>(
                        tooltip: 'Filter by status',
                        onSelected: (value) {
                          setState(() => _statusFilter = value);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'all', child: Text('All')),
                          PopupMenuItem(value: 'draft', child: Text('Draft')),
                          PopupMenuItem(value: 'sent', child: Text('Sent')),
                          PopupMenuItem(value: 'paid', child: Text('Paid')),
                        ],
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(40, 40),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Icon(Icons.filter_list),
                          onPressed: null,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Sort
                      PopupMenuButton<String>(
                        tooltip: 'Sort by',
                        onSelected: (value) {
                          setState(() => _sortBy = value);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'date-desc',
                            child: Text('Date (Newest)'),
                          ),
                          PopupMenuItem(
                            value: 'date-asc',
                            child: Text('Date (Oldest)'),
                          ),
                          PopupMenuItem(
                            value: 'amount-desc',
                            child: Text('Amount (High→Low)'),
                          ),
                          PopupMenuItem(
                            value: 'amount-asc',
                            child: Text('Amount (Low→High)'),
                          ),
                          PopupMenuItem(
                            value: 'billno-asc',
                            child: Text('Bill No. (A→Z)'),
                          ),
                          PopupMenuItem(
                            value: 'billno-desc',
                            child: Text('Bill No. (Z→A)'),
                          ),
                        ],
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(40, 40),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Icon(Icons.import_export),
                          onPressed: null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Invoice list
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 40,
                                  color: theme.hintColor.withOpacity(0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No invoices found',
                                  style: theme.textTheme.bodyMedium!.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: LayoutBuilder(
                                builder: (ctx, constraints) {
                                  // Use horizontal scroll if narrow.
                                  final table = _buildTable(
                                    context,
                                    filtered,
                                    constraints.maxWidth,
                                  );
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: constraints.maxWidth,
                                      ),
                                      child: table,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable(
    BuildContext context,
    List<Invoice> invoices,
    double width,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Theme(
      data: theme.copyWith(
        dataTableTheme: DataTableThemeData(
          headingRowColor: MaterialStateProperty.all(
            isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9), // Slate 800 / Slate 100
          ),
          dataRowColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.hovered)) {
                return theme.colorScheme.primary.withOpacity(isDark ? 0.1 : 0.04);
              }
              return null; // Use default
            },
          ),
          dividerThickness: 1,
          headingTextStyle: theme.textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.hintColor,
          ),
          dataTextStyle: theme.textTheme.bodyMedium!.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      child: DataTable(
        horizontalMargin: 24,
        columnSpacing: 24,
        headingRowHeight: 56,
        dataRowMinHeight: 64,
        dataRowMaxHeight: 64,
        columns: const [
          DataColumn(label: Text('Bill No.')),
          DataColumn(label: Text('Client')),
          DataColumn(label: Text('Date')),
          DataColumn(
            label: Text('Amount'),
            numeric: true,
          ),
          DataColumn(label: Text('Status')),
          DataColumn(
            label: Align(alignment: Alignment.centerRight, child: Text('Actions')),
          ),
        ],
        rows: invoices.map((inv) {
          final client = _getClient(inv.clientId);
          return DataRow(
            cells: [
              DataCell(
                Text(
                  inv.billNo,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(
                Text(
                  client?.name ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              DataCell(
                Text(
                  '${inv.date.day.toString().padLeft(2, '0')} ${_monthString(inv.date.month)} ${inv.date.year}',
                  style: TextStyle(color: theme.hintColor, fontSize: 13),
                ),
              ),
              DataCell(
                Text(
                  '₹${inv.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusBg(inv.status, theme),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _statusBg(inv.status, theme).withOpacity(0.5),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: inv.status,
                      iconSize: 16,
                      isDense: true,
                      style: theme.textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _statusText(inv.status, theme),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                        DropdownMenuItem(value: 'sent', child: Text('Sent')),
                        DropdownMenuItem(value: 'paid', child: Text('Paid')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        _updateInvoiceStatus(inv.id, value);
                      },
                    ),
                  ),
                ),
              ),
              DataCell(
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        color: theme.hintColor,
                        onPressed: () => _onEditInvoice(inv),
                      ),
                      IconButton(
                        tooltip: 'Print / Preview',
                        icon: const Icon(Icons.print_outlined, size: 20),
                        color: theme.hintColor,
                        onPressed: () => _onPreviewInvoice(inv),
                      ),
                      IconButton(
                        tooltip: 'Share on WhatsApp',
                        icon: const Icon(Icons.share, size: 20),
                        color: const Color(0xFF25D366), // WhatsApp green
                        onPressed: () => _shareOnWhatsApp(inv),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: theme.colorScheme.error,
                        onPressed: () => _deleteInvoice(inv.id),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _monthString(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(isDark ? 0.2 : 0.4),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall!.copyWith(
                    color: theme.hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.headlineMedium!.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
