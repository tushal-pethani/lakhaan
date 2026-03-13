import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:window_manager/window_manager.dart';

import 'clients/client_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'home_screen.dart';
import 'firebase_options.dart';
import 'login/login_screen.dart';
import 'services/firestore_service.dart';
import 'storage/app_data_store.dart';
import 'theme/app_theme.dart';
import 'invoices/public_invoice_screen.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // The Firestore C++ SDK persistence engine hangs on Windows, causing infinite loading.
    // Disabling it fixes the issue.
    if (!kIsWeb && Platform.isWindows) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    }
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  try {
    await AppDataStore.instance.init('signedOut');
  } catch (e) {
    debugPrint('AppDataStore init error: $e');
  }

  AppTheme.themeMode.value =
      AppDataStore.instance.settings.themeMode == 'dark'
          ? ThemeMode.dark
          : ThemeMode.light;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          initialRoute: '/',
          onGenerateRoute: (settings) {
            // Handle /invoice/:userId/:invoiceId
            if (settings.name != null && settings.name!.startsWith('/invoice/')) {
              final segments = settings.name!.split('/');
              // segments will be ['', 'invoice', 'userId', 'invoiceId']
              if (segments.length >= 4) {
                final userId = segments[2];
                final invoiceId = segments[3];
                return MaterialPageRoute(
                  builder: (context) => PublicInvoiceScreen(userId: userId, invoiceId: invoiceId),
                  settings: settings,
                );
              }
            }
            return null; // Let standard routes handle everything else
          },
          routes: {
            '/': (_) => const _AuthGate(),
            '/clients': (_) => const ClientsScreen(),
            '/dashboard': (_) => const DashboardScreen(),
          },
        );
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  String? _initializedEmailKey;
  bool _initializingStore = false;

  String _emailKey(String email) => Uri.encodeComponent(email.trim().toLowerCase());

  Future<void> _ensureStoreForEmail(String email) async {
    if (email.isEmpty) return;
    final key = _emailKey(email);
    if (_initializedEmailKey == key) return;
    if (_initializingStore) return;

    Future.microtask(() async {
      if (!mounted) return;
      setState(() => _initializingStore = true);
      
      try {
        // Load profile from Firestore with a timeout to prevent hanging
        try {
          final profileData = await FirestoreService.instance
              .getProfile()
              .timeout(const Duration(seconds: 10));
          if (profileData != null) {
            AppDataStore.instance.profile = StoredProfile(
              name: profileData['name'] as String? ?? 'Default User',
              email: profileData['email'] as String? ?? email,
              businessName: profileData['name'] as String? ?? 'Business',
              address: profileData['address'] as String? ?? '',
              city: profileData['city'] as String? ?? '',
              state: profileData['state'] as String? ?? '',
              pincode: profileData['pincode'] as String? ?? '',
              phone: profileData['phone'] as String? ?? '',
              gstNumber: profileData['gstNumber'] as String? ?? '',
              panNumber: profileData['panNumber'] as String?,
              bankName: profileData['bankName'] as String?,
              accountNumber: profileData['accountNumber'] as String?,
              ifscCode: profileData['ifscCode'] as String?,
              companyLogoBase64: profileData['companyLogoBase64'] as String?,
            );
          } else {
             AppDataStore.instance.profile = StoredProfile(
                name: 'Default User',
                email: email,
                businessName: 'Business',
                address: '',
                city: '',
                state: '',
                pincode: '',
                phone: '',
                gstNumber: '',
            );
          }
        } catch (e) {
          debugPrint('Failed to load profile from Firestore: $e');
           AppDataStore.instance.profile = StoredProfile(
              name: 'Default User',
              email: email,
              businessName: 'Business',
              address: '',
              city: '',
              state: '',
              pincode: '',
              phone: '',
              gstNumber: '',
          );
        }

        await AppDataStore.instance.init(key)
            .timeout(const Duration(seconds: 5));
        
        AppTheme.themeMode.value =
            AppDataStore.instance.settings.themeMode == 'dark'
                ? ThemeMode.dark
                : ThemeMode.light;
      } catch (e) {
        debugPrint('Error during store initialization: $e');
      } finally {
        if (mounted) {
          setState(() {
            _initializedEmailKey = key;
            _initializingStore = false;
          });
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _ensureStoreForEmail('default@lakhaan.com');
  }

  @override
  Widget build(BuildContext context) {
    if (_initializingStore && _initializedEmailKey == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text('Bypassing login and loading default user data...'),
            ],
          ),
        ),
      );
    }

    return const HomeScreen(isLoggedIn: true);
  }
}
