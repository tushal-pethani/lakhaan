import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../services/translation_service.dart';

class InvoiceFormClient {
  final String id;
  final String name;
  InvoiceFormClient({required this.id, required this.name});
}

class InvoiceFormItem {
  String id;
  String description;
  int quantity;
  String unit;
  double rate;
  double discount;
  double tax;
  InvoiceFormItem({
    String? id,
    this.description = '',
    this.quantity = 1,
    this.unit = 'pcs',
    this.rate = 0,
    this.discount = 0,
    this.tax = 0,
  }) : id = id ?? Uuid().v4();
  double get discountAmount => (quantity * rate) * (discount / 100);
  double get amount => (quantity * rate) - discountAmount + (tax ?? 0);
}

class InvoiceFormResult {
  final String clientId;
  final String billNo;
  final DateTime date;
  final String? chNo;
  final List<InvoiceFormItem> items;
  final double cgstRate;
  final double sgstRate;
  final double igstRate;
  final String theme;
  final String? termsAndConditions;

  InvoiceFormResult({
    required this.clientId,
    required this.billNo,
    required this.date,
    this.chNo,
    required this.items,
    required this.cgstRate,
    required this.sgstRate,
    required this.igstRate,
    required this.theme,
    this.termsAndConditions,
  });
}

const List<String> itemUnits = [
  'pcs',
  'mtrs',
  'kgs',
  'litres',
  'boxes',
  'sets',
  'dozen',
  'rolls',
  'pairs',
  'bags',
];

Future<InvoiceFormResult?> showInvoiceFormDialog(
  BuildContext context, {
  required List<InvoiceFormClient> clients,
  String? initialClientId,
  String? initialBillNo,
  DateTime? initialDate,
  String? initialChNo,
  List<InvoiceFormItem>? initialItems,
  double? initialCgstRate,
  double? initialSgstRate,
  double? initialIgstRate,
  String? initialTheme,
  String? initialTermsAndConditions,
  bool isEdit = false,
}) {
  final theme = Theme.of(context);
  String clientId = initialClientId ?? '';
  String billNo =
      initialBillNo ??
      'INV-1';
  DateTime date = initialDate ?? DateTime.now();
  String chNo = initialChNo ?? '';
  List<InvoiceFormItem> items = initialItems != null && initialItems.isNotEmpty
      ? initialItems
            .map(
              (e) => InvoiceFormItem(
                id: Uuid().v4(),
                description: e.description,
                quantity: e.quantity,
                unit: e.unit ?? 'pcs',
                rate: e.rate,
                discount: e.discount ?? 0,
                tax: e.tax ?? 0,
              ),
            )
            .toList()
      : [InvoiceFormItem()];
  double cgstRate = initialCgstRate ?? 9;
  double sgstRate = initialSgstRate ?? 9;
  double igstRate = initialIgstRate ?? 0;
  String themeKey = initialTheme ?? 'classic';
  String termsAndConditions = initialTermsAndConditions ?? '';
  final formKey = GlobalKey<FormState>();

  double subtotal() =>
      items.fold(0, (sum, item) => sum + (item.quantity * item.rate));
  double totalDiscount() =>
      items.fold(0, (sum, item) => sum + item.discountAmount);
  double totalTax() => items.fold(0, (sum, item) => sum + (item.tax ?? 0));
  double cgstAmount() => subtotal() * cgstRate / 100;
  double sgstAmount() => subtotal() * sgstRate / 100;
  double igstAmount() => subtotal() * igstRate / 100;
  double totalAmount() =>
      subtotal() -
      totalDiscount() +
      totalTax() +
      cgstAmount() +
      sgstAmount() +
      igstAmount();
  int totalQty() => items.fold(0, (sum, item) => sum + item.quantity);

  void addItem(StateSetter setState) =>
      setState(() => items.add(InvoiceFormItem()));
  void removeItem(StateSetter setState, int index) =>
      setState(() => items.removeAt(index));

  return showDialog<InvoiceFormResult>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final isDark = theme.brightness == Brightness.dark;
      return Dialog(
        elevation: 24,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 850),
          child: StatefulBuilder(
            builder: (ctx, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9), // Slate 800 or Slate 100
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isEdit ? Icons.edit_document : Icons.receipt_long,
                            color: theme.colorScheme.onPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? 'Edit Invoice' : 'New Invoice',
                                style: theme.textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEdit
                                    ? 'Update invoice details'
                                    : 'Create a new invoice',
                                style: theme.textTheme.bodySmall!.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(null),
                          icon: const Icon(Icons.close),
                          tooltip: 'Close',
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.surface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Invoice Details',
                                    style: theme.textTheme.titleSmall!.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: _buildDropdown(
                                          'Client *',
                                          theme,
                                          clientId,
                                          clients
                                              .map(
                                                (c) => DropdownMenuItem(
                                                  value: c.id,
                                                  child: Text(
                                                    c.name,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          (v) => setState(() => clientId = v ?? ''),
                                          required: true,
                                          hint: 'Select Client',
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 2,
                                        child: _buildTextField(
                                          'Bill No. *',
                                          billNo,
                                          (v) => setState(() => billNo = v),
                                          theme,
                                          required: true,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildTextField(
                                          'CH No.',
                                          chNo,
                                          (v) => setState(() => chNo = v),
                                          theme,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDatePicker(
                                          'Date',
                                          theme,
                                          date,
                                          (picked) => setState(() => date = picked),
                                          ctx,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildDropdown(
                                          'Theme',
                                          theme,
                                          themeKey,
                                          const [
                                            DropdownMenuItem(
                                              value: 'classic',
                                              child: Text('Classic Blue'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'modern',
                                              child: Text('Modern Green'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'professional',
                                              child: Text('Professional Dark'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'plain',
                                              child: Text('Plain White'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'royal',
                                              child: Text('Royal Purple'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'sunset',
                                              child: Text('Sunset Orange'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'ocean',
                                              child: Text('Ocean Blue'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'ruby',
                                              child: Text('Ruby Red'),
                                            ),
                                          ],
                                          (v) => setState(
                                            () => themeKey = v ?? 'classic',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Items',
                                        style: theme.textTheme.titleSmall!.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => addItem(setState),
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text('Add Item'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: theme.dividerColor),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                          ),
                                          child: Row(
                                            children: [
                                              _tableHeader('#', flex: 0.5),
                                              _tableHeader(
                                                'Item Description',
                                                flex: 3,
                                              ),
                                              _tableHeader('Qty', flex: 1),
                                              _tableHeader('Unit', flex: 1),
                                              _tableHeader('Rate (Rs.)', flex: 1.2),
                                              _tableHeader('Disc. (%)', flex: 1),
                                              _tableHeader('Tax (Rs.)', flex: 1),
                                              _tableHeader('Amount', flex: 1.2),
                                              const SizedBox(width: 40),
                                            ],
                                          ),
                                        ),
                                        ...List.generate(
                                          items.length,
                                          (i) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                top: BorderSide(
                                                  color: theme.dividerColor
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                _tableCell('${i + 1}', flex: 0.5),
                                                _tableInput(
                                                  items[i].id + '_desc',
                                                  items[i].description,
                                                  (v) => setState(
                                                    () => items[i].description = v,
                                                  ),
                                                  flex: 3,
                                                  highlight: true,
                                                  placeholder: 'Enter item description',
                                                ),
                                                _tableInput(
                                                  items[i].id + '_qty',
                                                  items[i].quantity.toString(),
                                                  (v) => setState(
                                                    () => items[i].quantity =
                                                        int.tryParse(v) ?? 1,
                                                  ),
                                                  flex: 1,
                                                  keyboardType: TextInputType.number,
                                                ),
                                                _tableDropdown(
                                                  items[i].id + '_unit',
                                                  items[i].unit,
                                                  itemUnits,
                                                  (v) => setState(
                                                    () => items[i].unit = v ?? 'pcs',
                                                  ),
                                                  flex: 1,
                                                ),
                                                _tableInput(
                                                  items[i].id + '_rate',
                                                  items[i].rate.toStringAsFixed(2),
                                                  (v) => setState(
                                                    () => items[i].rate =
                                                        double.tryParse(v) ?? 0,
                                                  ),
                                                  flex: 1.2,
                                                  keyboardType: TextInputType.number,
                                                ),
                                                _tableInput(
                                                  items[i].id + '_disc',
                                                  items[i].discount.toStringAsFixed(
                                                    2,
                                                  ),
                                                  (v) => setState(
                                                    () => items[i].discount =
                                                        double.tryParse(v) ?? 0,
                                                  ),
                                                  flex: 1,
                                                  keyboardType: TextInputType.number,
                                                ),
                                                _tableInput(
                                                  items[i].id + '_tax',
                                                  items[i].tax.toStringAsFixed(2),
                                                  (v) => setState(
                                                    () => items[i].tax =
                                                        double.tryParse(v) ?? 0,
                                                  ),
                                                  flex: 1,
                                                  keyboardType: TextInputType.number,
                                                ),
                                                _tableCell(
                                                  'Rs.${items[i].amount.toStringAsFixed(2)}',
                                                  flex: 1.2,
                                                  bold: true,
                                                ),
                                                SizedBox(
                                                  width: 40,
                                                  child: items.length > 1
                                                      ? IconButton(
                                                          icon: Icon(
                                                            Icons.delete_outline,
                                                            color: theme
                                                                .colorScheme
                                                                .error,
                                                            size: 20,
                                                          ),
                                                          onPressed: () =>
                                                              removeItem(setState, i),
                                                        )
                                                      : const SizedBox(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Taxes & Additional Details',
                                    style: theme.textTheme.titleSmall!.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          'CGST %',
                                          cgstRate.toStringAsFixed(1),
                                          (v) => setState(
                                            () => cgstRate = double.tryParse(v) ?? 0,
                                          ),
                                          theme,
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildTextField(
                                          'SGST %',
                                          sgstRate.toStringAsFixed(1),
                                          (v) => setState(
                                            () => sgstRate = double.tryParse(v) ?? 0,
                                          ),
                                          theme,
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildTextField(
                                          'IGST %',
                                          igstRate.toStringAsFixed(1),
                                          (v) => setState(
                                            () => igstRate = double.tryParse(v) ?? 0,
                                          ),
                                          theme,
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    'Terms and Conditions',
                                    termsAndConditions,
                                    (v) => setState(() => termsAndConditions = v),
                                    theme,
                                    maxLines: 3,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Qty: ${totalQty()}',
                                        style: theme.textTheme.bodyMedium!
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _totalRow('Subtotal', subtotal(), theme),
                                  _totalRow(
                                    'Discount',
                                    -totalDiscount(),
                                    theme,
                                  ),
                                  _totalRow('Tax', totalTax(), theme),
                                  if (cgstRate > 0)
                                    _totalRow(
                                      'CGST (${cgstRate.toStringAsFixed(1)}%)',
                                      cgstAmount(),
                                      theme,
                                    ),
                                  if (sgstRate > 0)
                                    _totalRow(
                                      'SGST (${sgstRate.toStringAsFixed(1)}%)',
                                      sgstAmount(),
                                      theme,
                                    ),
                                  if (igstRate > 0)
                                    _totalRow(
                                      'IGST (${igstRate.toStringAsFixed(1)}%)',
                                      igstAmount(),
                                      theme,
                                    ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Net Payable',
                                        style: theme.textTheme.bodyMedium!
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                      ),
                                      Text(
                                        'Rs.${totalAmount().toStringAsFixed(2)}',
                                        style: theme.textTheme.titleMedium!
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9), // Slate 800 or Slate 100
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                        border: Border(
                        top: BorderSide(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(null),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;
                              if (items.isEmpty) return;
                              Navigator.of(dialogContext).pop(
                                InvoiceFormResult(
                                  clientId: clientId,
                                  billNo: billNo,
                                  date: date,
                                  chNo: chNo.isEmpty ? null : chNo,
                                  items: List<InvoiceFormItem>.from(items),
                                  cgstRate: cgstRate,
                                  sgstRate: sgstRate,
                                  igstRate: igstRate,
                                  theme: themeKey,
                                  termsAndConditions: termsAndConditions.isEmpty
                                      ? null
                                      : termsAndConditions,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isEdit ? 'Update Invoice' : 'Create Invoice',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

Widget _tableHeader(String text, {double flex = 1}) => Expanded(
  flex: (flex * 10).toInt(),
  child: Text(
    text,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    textAlign: TextAlign.center,
  ),
);
Widget _tableCell(String text, {double flex = 1, bool bold = false}) =>
    Expanded(
      flex: (flex * 10).toInt(),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
Widget _tableInput(
  String keyString,
  String value,
  Function(String) onChanged, {
  double flex = 1,
  TextInputType? keyboardType,
  bool highlight = false,
  String? placeholder,
}) => Expanded(
  flex: (flex * 10).toInt(),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: TextFormField(
      key: ValueKey(keyString),
      initialValue: value,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 12,
        fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
      ),
      textAlign: highlight ? TextAlign.left : TextAlign.center,
      decoration: InputDecoration(
        isDense: true,
        hintText: placeholder,
        hintStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: highlight ? Colors.blueAccent.withOpacity(0.3) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: highlight ? Colors.blueAccent : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        filled: true,
        fillColor: highlight ? Colors.blueAccent.withOpacity(0.04) : Colors.transparent,
      ),
    ),
  ),
);
Widget _tableDropdown(
  String keyString,
  String value,
  List<String> items,
  Function(String?) onChanged, {
  double flex = 1,
}) => Expanded(
  flex: (flex * 10).toInt(),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: DropdownButtonFormField<String>(
      key: ValueKey(keyString),
      value: value,
      items: items
          .map(
            (u) => DropdownMenuItem(
              value: u,
              child: Text(u, style: const TextStyle(fontSize: 12)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      isDense: true,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.circular(6),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.circular(6),
        ),
        filled: true,
        fillColor: Colors.transparent,
      ),
    ),
  ),
);

Widget _buildDropdown(
  String label,
  ThemeData theme,
  String value,
  List<DropdownMenuItem<String>> items,
  Function(String?) onChanged, {
  bool required = false,
  String? hint,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(label.tr, style: theme.textTheme.bodySmall),
    const SizedBox(height: 4),
    DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      hint: hint != null ? Text(hint.tr, style: TextStyle(color: theme.hintColor)) : null,
      items: items,
      onChanged: onChanged,
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'Required' : null
          : null,
    ),
  ],
);

Widget _buildTextField(
  String label,
  String value,
  Function(String) onChanged,
  ThemeData theme, {
  bool required = false,
  TextInputType? keyboardType,
  int maxLines = 1,
}) => TextFormField(
  initialValue: value,
  maxLines: maxLines,
  decoration: InputDecoration(
    labelText: label.tr,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  ),
  keyboardType: keyboardType,
  validator: required
      ? (v) => (v == null || v.isEmpty) ? 'Required' : null
      : null,
  onChanged: onChanged,
);

Widget _buildDatePicker(
  String label,
  ThemeData theme,
  DateTime date,
  Function(DateTime) onChanged,
  BuildContext context,
) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(label.tr, style: theme.textTheme.bodySmall),
    const SizedBox(height: 4),
    InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        child: Text(
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
        ),
      ),
    ),
  ],
);

Widget _totalRow(String label, double value, ThemeData theme) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 2),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label.tr,
        style: theme.textTheme.bodySmall!.copyWith(color: theme.hintColor),
      ),
      Text('Rs.${value.toStringAsFixed(2)}', style: theme.textTheme.bodySmall),
    ],
  ),
);
