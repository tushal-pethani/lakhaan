import 'dart:convert';
import 'dart:io';

import 'package:billings/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../auth/auth_service.dart';
import '../storage/app_data_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  bool isSignup = false;
  bool loading = false;
  bool showPassword = false;
  bool gstVerified = false;
  bool verifying = false;

  String email = '';
  String password = '';
  String name = '';
  String gstNumber = '';
  String businessName = '';
  String address = '';
  String stateName = '';
  String city = '';
  String pincode = '';
  String phone = '';
  String bankName = '';
  String accountNumber = '';
  String ifscCode = '';
  String? companyLogoBase64;

  final ImagePicker _picker = ImagePicker();

  String _friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered. Please sign in.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password is too weak. Please choose a stronger password.';
        case 'user-not-found':
          return 'No account found for this email. Please sign up.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'network-request-failed':
          return 'Network error. Please check your internet and try again.';
        case 'keychain-error':
          return 'Keychain access error on macOS. This is usually fixed by enabling Keychain access groups entitlements and running the app again.';
        default:
          return e.message ?? 'Authentication failed (${e.code}).';
      }
    }

    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        return 'Firestore permission denied. Update Firestore rules to allow signed-in users to write/read their profile.';
      }
      if (e.code == 'failed-precondition') {
        return 'Firestore is not ready/disabled for this project. Enable Cloud Firestore in Firebase console.';
      }
      return e.message ?? 'Firebase error (${e.code}).';
    }

    return 'Something went wrong. Please try again.';
  }

  int _passwordStrength(String pw) {
    int score = 0;
    if (pw.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pw)) score++;
    if (RegExp(r'[0-9]').hasMatch(pw)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(pw)) score++;
    return score;
  }

  String get strengthLabel {
    final strength = _passwordStrength(password);
    const labels = ['', 'Weak', 'Fair', 'Good', 'Strong'];
    return labels[strength];
  }

  Color strengthColor(BuildContext context, int i) {
    final strength = _passwordStrength(password);
    if (i > strength) {
      return Theme.of(context).colorScheme.surfaceVariant;
    }
    switch (strength) {
      case 1:
        return Theme.of(context).colorScheme.error;
      case 2:
        return Colors.amber;
      case 3:
        return Theme.of(context).colorScheme.primary;
      case 4:
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.surfaceVariant;
    }
  }

  Future<Map<String, String>> _verifyGstApi(String gst) async {
    // TODO: Replace with your real GST API call.
    await Future.delayed(const Duration(seconds: 1));
    // Simulate some data:
    return {
      'businessName': 'Sample Business Pvt. Ltd.',
      'address': '123, Sample Street',
      'stateName': 'Maharashtra',
      'city': 'Mumbai',
      'pincode': '400001',
      'phone': '9876543210',
    };
  }

  Future<void> _verifyGst() async {
    if (gstNumber.length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GST number must be 15 characters')),
      );
      return;
    }
    setState(() {
      verifying = true;
    });
    try {
      final result = await _verifyGstApi(gstNumber);
      setState(() {
        businessName = result['businessName'] ?? businessName;
        address = result['address'] ?? address;
        stateName = result['stateName'] ?? stateName;
        city = result['city'] ?? city;
        pincode = result['pincode'] ?? pincode;
        phone = result['phone'] ?? phone;
        gstVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GST Number verified successfully!')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GST verification failed')),
      );
    }
    setState(() {
      verifying = false;
    });
  }

  Future<void> _pickLogo() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await File(file.path).readAsBytes();
    setState(() {
      companyLogoBase64 = base64Encode(bytes);
    });
  }

  void _removeLogo() {
    setState(() {
      companyLogoBase64 = null;
    });
  }

  Future<void> _login(String email, String password) async {
    final profile = await AuthService.instance.signInWithEmail(
      email: email,
      password: password,
    );

    // Initialize local store using email-keyed folder, then keep profile locally.
    await AppDataStore.instance.init(AuthService.instance.emailKey(profile.email));
    AppDataStore.instance.profile = StoredProfile(
      name: profile.name,
      email: profile.email,
      businessName: profile.name.isEmpty ? 'Business' : profile.name,
      address: '',
      city: '',
      state: '',
      pincode: '',
      phone: '',
      gstNumber: profile.gstNumber,
    );
    await AppDataStore.instance.saveProfile();
  }

  Future<void> _signup() async {
    // 1) Create account in Firebase Auth (password stays only in Auth)
    // 2) Store name/email/gstNumber in Firestore
    final cloudProfile = await AuthService.instance.signUpWithEmail(
      email: email,
      password: password,
      name: name,
      gstNumber: gstNumber,
    );

    // 3) Initialize local store using email-keyed folder
    await AppDataStore.instance.init(
      AuthService.instance.emailKey(cloudProfile.email),
    );

    // 4) Persist profile locally (and keep invoices/clients local-only)
    try {
      AppDataStore.instance.profile = StoredProfile(
        name: name.trim(),
        email: cloudProfile.email.trim(),
        businessName: businessName.trim().isEmpty
            ? name.trim()
            : businessName.trim(),
        address: address.trim(),
        city: city.trim(),
        state: stateName.trim(),
        pincode: pincode.trim(),
        phone: phone.trim(),
        gstNumber: gstNumber.trim(),
        bankName: bankName.trim().isEmpty ? null : bankName.trim(),
        accountNumber:
            accountNumber.trim().isEmpty ? null : accountNumber.trim(),
        ifscCode: ifscCode.trim().isEmpty ? null : ifscCode.trim(),
        companyLogoBase64: companyLogoBase64,
      );
      await AppDataStore.instance.saveProfile();
    } catch (e, st) {
      // Log the exact error so we can debug if signup fails.
      // ignore: avoid_print
      print('Signup saveProfile error: $e\n$st');
      rethrow;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final strength = _passwordStrength(password);
    if (isSignup && strength < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please use a stronger password')),
      );
      return;
    }

    setState(() {
      loading = true;
    });
    try {
      if (isSignup) {
        // For signup, _signup() already navigates to the dashboard.
        await _signup();
      } else {
        await _login(email, password);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome back!')),
        );
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('Auth submit error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(e))),
      );
    }
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // A sleek background utilizing the theme.
    final bgGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Container(
              width: 440,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.5)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(isDark ? 0.3 : 0.5),
                  width: 1,
                ),
              ),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _buildFormContent(theme),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(ThemeData theme) {
    return Column(
      key: ValueKey<bool>(isSignup),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.description,
                  size: 28, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'Lakhaan',
              style: theme.textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          isSignup ? 'Create account' : 'Welcome back',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall!.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isSignup
              ? 'Start generating professional invoices'
              : 'Sign in to your account to continue',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium!.copyWith(
            color: theme.hintColor,
          ),
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isSignup) ...[
                _TextField(
                  label: 'Full Name',
                  hint: 'Rajesh Kumar',
                  initialValue: name,
                  onSaved: (v) => name = v ?? '',
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
              ],
              _TextField(
                label: 'Email',
                hint: 'you@company.com',
                keyboardType: TextInputType.emailAddress,
                initialValue: email,
                onSaved: (v) => email = v ?? '',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _PasswordField(
                label: 'Password',
                password: password,
                showPassword: showPassword,
                onChanged: (v) => setState(() => password = v),
                onSaved: (v) => password = v ?? '',
                isSignup: isSignup,
                strengthBuilder: (ctx) {
                  if (!isSignup || password.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final strength = _passwordStrength(password);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(4, (index) {
                          final i = index + 1;
                          return Expanded(
                            child: Container(
                              height: 4,
                              margin: EdgeInsets.only(
                                  right: index < 3 ? 4 : 0),
                              decoration: BoxDecoration(
                                color: strengthColor(ctx, i),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Strength: $strengthLabel',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: theme.hintColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
                toggleShow: () =>
                    setState(() => showPassword = !showPassword),
              ),
              if (isSignup) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                _TextField(
                  label: 'GST Number',
                  hint: '27AABCU9603R1ZM',
                  maxLength: 15,
                  textCapitalization: TextCapitalization.characters,
                  initialValue: gstNumber,
                  onSaved: (v) => gstNumber = (v ?? '').toUpperCase(),
                  onChanged: (v) {
                    setState(() {
                      gstNumber = v.toUpperCase();
                      gstVerified = false;
                    });
                  },
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Required'
                      : (v.length != 15 ? 'Must be 15 characters' : null),
                  suffix: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      onPressed: verifying || gstVerified ? null : _verifyGst,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        backgroundColor: gstVerified
                            ? Colors.green
                            : theme.colorScheme.primary,
                        minimumSize: const Size(0, 36),
                      ),
                      child: verifying
                          ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : Text(gstVerified ? 'Verified ✓' : 'Live Verify'),
                    ),
                  ),
                ),
                if (gstVerified) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TextField(
                          label: 'Business Name',
                          initialValue: businessName,
                          onSaved: (v) => businessName = v ?? '',
                        ),
                        const SizedBox(height: 12),
                        _TextField(
                          label: 'Address',
                          initialValue: address,
                          onSaved: (v) => address = v ?? '',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _TextField(
                                label: 'State',
                                initialValue: stateName,
                                onSaved: (v) => stateName = v ?? '',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TextField(
                                label: 'City',
                                initialValue: city,
                                onSaved: (v) => city = v ?? '',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _TextField(
                                label: 'Pincode',
                                initialValue: pincode,
                                keyboardType: TextInputType.number,
                                onSaved: (v) => pincode = v ?? '',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TextField(
                                label: 'Phone',
                                initialValue: phone,
                                keyboardType: TextInputType.phone,
                                onSaved: (v) => phone = v ?? '',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'Bank Details (Optional)',
                          style: theme.textTheme.titleSmall!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add bank details to display on invoices',
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _TextField(
                          label: 'Bank Name',
                          hint: 'HDFC Bank',
                          initialValue: bankName,
                          onSaved: (v) => bankName = v ?? '',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _TextField(
                                label: 'Account Number',
                                hint: '1234567890',
                                initialValue: accountNumber,
                                keyboardType: TextInputType.number,
                                onSaved: (v) => accountNumber = v ?? '',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TextField(
                                label: 'IFSC Code',
                                hint: 'HDFC0001234',
                                textCapitalization: TextCapitalization.characters,
                                initialValue: ifscCode,
                                onSaved: (v) =>
                                    ifscCode = (v ?? '').toUpperCase(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Company Logo (Optional)',
                          style: theme.textTheme.titleSmall!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (companyLogoBase64 != null)
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.memory(
                                  base64Decode(companyLogoBase64!),
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                top: -8,
                                right: -8,
                                child: InkWell(
                                  onTap: _removeLogo,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.error,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      size: 14,
                                      color: theme.colorScheme.onError,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: _pickLogo,
                            icon: const Icon(Icons.upload, size: 18),
                            label: const Text('Upload Logo'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: loading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : Text(
                        isSignup ? 'Create Account' : 'Sign In',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isSignup ? 'Already have an account?' : 'Don\'t have an account?',
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.hintColor,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  isSignup = !isSignup;
                  gstVerified = false;
                });
              },
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: isSignup ? 'Sign in' : 'Create one',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  const _FeatureChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.greenAccent),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? initialValue;
  final TextInputType? keyboardType;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final Widget? suffix;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  const _TextField({
    required this.label,
    this.hint,
    this.initialValue,
    this.keyboardType,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.suffix,
    this.onSaved,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: initialValue,
            keyboardType: keyboardType,
            maxLength: maxLength,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              suffixIcon: suffix != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: suffix,
                    )
                  : null,
            ),
            validator: validator,
            onSaved: onSaved,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final String password;
  final bool showPassword;
  final bool isSignup;
  final ValueChanged<String> onChanged;
  final FormFieldSetter<String>? onSaved;
  final VoidCallback toggleShow;
  final Widget Function(BuildContext) strengthBuilder;

  const _PasswordField({
    required this.label,
    required this.password,
    required this.showPassword,
    required this.isSignup,
    required this.onChanged,
    required this.toggleShow,
    required this.strengthBuilder,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          TextFormField(
            obscureText: !showPassword,
            onChanged: onChanged,
            onSaved: onSaved,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Required' : null,
            decoration: InputDecoration(
              hintText: '••••••••',
              suffixIcon: IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: toggleShow,
              ),
            ),
          ),
          strengthBuilder(context),
        ],
      ),
    );
  }
}