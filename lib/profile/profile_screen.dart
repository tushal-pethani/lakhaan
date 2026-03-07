import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../storage/app_data_store.dart';
import '../services/firestore_service.dart';
import 'package:flutter/foundation.dart';

Future<void> showProfileDialog(BuildContext context) async {
  final profile = AppDataStore.instance.profile;

  String name = profile?.name ?? 'User Name';
  String email = profile?.email ?? 'user@example.com';
  String businessName = profile?.businessName ?? 'Business Name';
  String address = profile?.address ?? 'Street 1';
  String state = profile?.state ?? 'State';
  String city = profile?.city ?? 'City';
  String pincode = profile?.pincode ?? '000000';
  String phone = profile?.phone ?? '9999999999';
  String gstNumber = profile?.gstNumber ?? '27ABCDE1234F1Z5';
  String panNumber = profile?.panNumber ?? '';
  String bankName = profile?.bankName ?? '';
  String accountNumber = profile?.accountNumber ?? '';
  String ifscCode = profile?.ifscCode ?? '';
  String? companyLogoBase64 = profile?.companyLogoBase64;

  final formKey = GlobalKey<FormState>();
  bool loading = false;

  final ImagePicker picker = ImagePicker();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final theme = Theme.of(ctx);

      return StatefulBuilder(
        builder: (ctx, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550, maxHeight: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.person,
                            color: theme.colorScheme.onPrimary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Profile',
                                style: theme.textTheme.titleLarge!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Update your business information',
                                style: theme.textTheme.bodySmall!.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Company Logo',
                              style: theme.textTheme.titleSmall!.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (companyLogoBase64 != null)
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: theme
                                                .colorScheme
                                                .outlineVariant,
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Image.memory(
                                          base64Decode(companyLogoBase64!),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: -8,
                                        right: -8,
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            size: 18,
                                            color: theme.colorScheme.onError,
                                          ),
                                          style: IconButton.styleFrom(
                                            backgroundColor:
                                                theme.colorScheme.error,
                                            padding: const EdgeInsets.all(4),
                                          ),
                                          onPressed: () => setState(
                                            () => companyLogoBase64 = null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.colorScheme.outlineVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: IconButton(
                                      onPressed: () async {
                                        final XFile? file = await picker
                                            .pickImage(
                                              source: ImageSource.gallery,
                                            );
                                        if (file != null) {
                                          final bytes = await file.readAsBytes();
                                          setState(
                                            () => companyLogoBase64 =
                                                base64Encode(bytes),
                                          );
                                        }
                                      },
                                      icon: Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 32,
                                        color: theme.hintColor,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Upload Logo',
                                      style: theme.textTheme.bodyMedium!
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Recommended: Square image\nPNG or JPG',
                                      style: theme.textTheme.bodySmall!
                                          .copyWith(color: theme.hintColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    'Full Name',
                                    Icons.person_outline,
                                    name,
                                    (v) => name = v,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    'Email',
                                    Icons.email_outlined,
                                    email,
                                    (v) => email = v,
                                    enabled: false,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    'Phone',
                                    Icons.phone_outlined,
                                    phone,
                                    (v) => phone = v,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    'GST Number',
                                    Icons.numbers,
                                    gstNumber,
                                    (v) => gstNumber = v,
                                    enabled: false,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    'PAN Number',
                                    Icons.credit_card,
                                    panNumber,
                                    (v) => panNumber = v,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Business Details',
                              style: theme.textTheme.titleSmall!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInputField(
                              'Business Name',
                              Icons.business_outlined,
                              businessName,
                              (v) => businessName = v,
                            ),
                            const SizedBox(height: 12),
                            _buildInputField(
                              'Address',
                              Icons.location_on_outlined,
                              address,
                              (v) => address = v,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    'City',
                                    Icons.location_city,
                                    city,
                                    (v) => city = v,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    'State',
                                    Icons.map,
                                    state,
                                    (v) => state = v,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    'Pincode',
                                    Icons.pin_drop,
                                    pincode,
                                    (v) => pincode = v,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Bank Details',
                              style: theme.textTheme.titleSmall!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInputField(
                              'Bank Name',
                              Icons.account_balance,
                              bankName,
                              (v) => bankName = v,
                              hint: 'e.g., State Bank of India',
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    'Account Number',
                                    Icons.credit_card,
                                    accountNumber,
                                    (v) => accountNumber = v,
                                    keyboardType: TextInputType.number,
                                    hint: 'e.g., 1234567890',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    'IFSC Code',
                                    Icons.code,
                                    ifscCode,
                                    (v) => ifscCode = v,
                                    hint: 'e.g., SBIN0001234',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark 
                          ? const Color(0xFF1E293B) 
                          : const Color(0xFFF1F5F9), // Slate 800 or Slate 100
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
                            onPressed: () => Navigator.of(ctx).pop(),
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
                            onPressed: loading
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate())
                                      return;
                                    formKey.currentState!.save();
                                    setState(() => loading = true);
                                    AppDataStore.instance.profile =
                                        StoredProfile(
                                          name: name,
                                          email: email,
                                          businessName: businessName,
                                          address: address,
                                          city: city,
                                          state: state,
                                          pincode: pincode,
                                          phone: phone,
                                          gstNumber: gstNumber,
                                          panNumber: panNumber.isEmpty
                                              ? null
                                              : panNumber,
                                          bankName: bankName,
                                          accountNumber: accountNumber,
                                          ifscCode: ifscCode,
                                          companyLogoBase64: companyLogoBase64,
                                        );
                                    if (kIsWeb) {
                                      await FirestoreService.instance.saveProfile({
                                        'name': name,
                                        'email': email,
                                        'businessName': businessName,
                                        'address': address,
                                        'city': city,
                                        'state': state,
                                        'pincode': pincode,
                                        'phone': phone,
                                        'gstNumber': gstNumber,
                                        'panNumber': panNumber.isEmpty ? null : panNumber,
                                        'bankName': bankName,
                                        'accountNumber': accountNumber,
                                        'ifscCode': ifscCode,
                                        'companyLogoBase64': companyLogoBase64,
                                      });
                                    }
                                    await AppDataStore.instance.saveProfile();
                                    setState(() => loading = false);
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Profile updated successfully!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      Navigator.of(ctx).pop();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: loading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildInputField(
  String label,
  IconData icon,
  String value,
  Function(String) onChanged, {
  bool enabled = true,
  int maxLines = 1,
  TextInputType? keyboardType,
  String? hint,
}) {
  return TextFormField(
    initialValue: value,
    enabled: enabled,
    maxLines: maxLines,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
    ),
    onChanged: onChanged,
  );
}
