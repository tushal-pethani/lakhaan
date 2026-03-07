import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Firebase options are not configured for this platform: $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCneGvLNW-kvkt04KCfie5URpeFMK-URME",
    authDomain: "billings-app-77b3e.firebaseapp.com",
    projectId: "billings-app-77b3e",
    storageBucket: "billings-app-77b3e.firebasestorage.app",
    messagingSenderId: "270189702621",
    appId: "1:270189702621:web:cd36515704f6802721da34",
    measurementId: "G-MLLCL16H0Q",
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCn9h6RBvUAbsPPHKDNQcRaRhw9p9WL6zU',
    appId: '1:270189702621:ios:7319177c89e75da821da34',
    messagingSenderId: '270189702621',
    projectId: 'billings-app-77b3e',
    storageBucket: 'billings-app-77b3e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCn9h6RBvUAbsPPHKDNQcRaRhw9p9WL6zU',
    appId: '1:270189702621:ios:7319177c89e75da821da34',
    messagingSenderId: '270189702621',
    projectId: 'billings-app-77b3e',
    storageBucket: 'billings-app-77b3e.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCn9h6RBvUAbsPPHKDNQcRaRhw9p9WL6zU',
    appId: '1:270189702621:android:abc123',
    messagingSenderId: '270189702621',
    projectId: 'billings-app-77b3e',
    storageBucket: 'billings-app-77b3e.firebasestorage.app',
  );
}
