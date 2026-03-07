import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:window_manager/window_manager.dart';

import 'clients/client_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'home_screen.dart';
import 'firebase_options.dart';
import 'login/login_screen.dart';
import 'services/firestore_service.dart';
import 'storage/app_data_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
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
          home: const _AuthGate(),
          routes: {
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

  Future<void> _ensureStoreFor(User user) async {
    final email = user.email;
    if (email == null || email.isEmpty) return;
    final key = _emailKey(email);
    if (_initializedEmailKey == key) return;
    if (_initializingStore) return;

    // Skip on web since storage is not available
    if (kIsWeb) {
      // Load profile from Firestore on web
      final profileData = await FirestoreService.instance.getProfile();
      if (profileData != null) {
        AppDataStore.instance.profile = StoredProfile(
          name: profileData['name'] as String? ?? '',
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
      }
      
      if (mounted) {
        setState(() => _initializedEmailKey = key);
      }
      return;
    }

    setState(() => _initializingStore = true);
    await AppDataStore.instance.init(key);
    AppTheme.themeMode.value =
        AppDataStore.instance.settings.themeMode == 'dark'
            ? ThemeMode.dark
            : ThemeMode.light;
    if (mounted) {
      setState(() {
        _initializedEmailKey = key;
        _initializingStore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const HomeScreen(isLoggedIn: false);
        }

        _ensureStoreFor(user);

        if (_initializingStore && _initializedEmailKey == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const HomeScreen(isLoggedIn: true);
      },
    );
  }
}
