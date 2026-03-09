import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

/// Simple encrypted JSON data store for Lakhaan.
///
/// On macOS, data is stored under:
///   /Library/Application Support/lakhaanData/(username)/
///
/// Files (all AES-encrypted JSON):
///   - invoices.json.enc
///   - clients.json.enc
///   - profile.json.enc
///   - settings.json.enc
///
/// NOTE: This is a basic implementation for local persistence, not
/// enterprise-grade security.

class StoredInvoiceItem {
  final String description;
  final int quantity;
  final String unit;
  final double rate;
  final double discount;
  final double tax;

  StoredInvoiceItem({
    required this.description,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.discount,
    required this.tax,
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    'quantity': quantity,
    'unit': unit,
    'rate': rate,
    'discount': discount,
    'tax': tax,
  };

  factory StoredInvoiceItem.fromJson(Map<String, dynamic> json) {
    return StoredInvoiceItem(
      description: json['description'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unit: json['unit'] as String? ?? 'pcs',
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StoredInvoice {
  final String id;
  final String billNo;
  final String clientId;
  final String dateIso;
  final double totalAmount;
  final String status;
  final String? theme;
  final List<StoredInvoiceItem>? items;
  final double? cgstRate;
  final double? sgstRate;
  final double? igstRate;
  final String? chNo;
  final String? termsAndConditions;

  StoredInvoice({
    required this.id,
    required this.billNo,
    required this.clientId,
    required this.dateIso,
    required this.totalAmount,
    required this.status,
    this.theme,
    this.items,
    this.cgstRate,
    this.sgstRate,
    this.igstRate,
    this.chNo,
    this.termsAndConditions,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'billNo': billNo,
    'clientId': clientId,
    'dateIso': dateIso,
    'totalAmount': totalAmount,
    'status': status,
    'theme': theme,
    'items': items?.map((e) => e.toJson()).toList(),
    'cgstRate': cgstRate,
    'sgstRate': sgstRate,
    'igstRate': igstRate,
    'chNo': chNo,
    'termsAndConditions': termsAndConditions,
  };

  factory StoredInvoice.fromJson(Map<String, dynamic> json) {
    return StoredInvoice(
      id: json['id'] as String,
      billNo: json['billNo'] as String,
      clientId: json['clientId'] as String,
      dateIso: json['dateIso'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'] as String,
      theme: json['theme'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => StoredInvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      cgstRate: (json['cgstRate'] as num?)?.toDouble(),
      sgstRate: (json['sgstRate'] as num?)?.toDouble(),
      igstRate: (json['igstRate'] as num?)?.toDouble(),
      chNo: json['chNo'] as String?,
      termsAndConditions: json['termsAndConditions'] as String?,
    );
  }
}

class StoredClient {
  final String id;
  final String name;
  final String gstNumber;
  final String? panNumber;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String phone;
  final String email;

  StoredClient({
    required this.id,
    required this.name,
    required this.gstNumber,
    this.panNumber,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gstNumber': gstNumber,
    'panNumber': panNumber,
    'address': address,
    'city': city,
    'state': state,
    'pincode': pincode,
    'phone': phone,
    'email': email,
  };

  factory StoredClient.fromJson(Map<String, dynamic> json) {
    return StoredClient(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      gstNumber: json['gstNumber'] as String? ?? '',
      panNumber: json['panNumber'] as String?,
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}

class StoredProfile {
  String name;
  String email;
  String businessName;
  String address;
  String city;
  String state;
  String pincode;
  String phone;
  String gstNumber;
  String? panNumber;
  String? bankName;
  String? accountNumber;
  String? ifscCode;
  String? companyLogoBase64;
  String? hsnNumber;

  StoredProfile({
    required this.name,
    required this.email,
    required this.businessName,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone,
    required this.gstNumber,
    this.panNumber,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.companyLogoBase64,
    this.hsnNumber,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'businessName': businessName,
    'address': address,
    'city': city,
    'state': state,
    'pincode': pincode,
    'phone': phone,
    'gstNumber': gstNumber,
    'panNumber': panNumber,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'ifscCode': ifscCode,
    'companyLogoBase64': companyLogoBase64,
    'hsnNumber': hsnNumber,
  };

  factory StoredProfile.fromJson(Map<String, dynamic> json) {
    return StoredProfile(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      gstNumber: json['gstNumber'] as String? ?? '',
      panNumber: json['panNumber'] as String?,
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      ifscCode: json['ifscCode'] as String?,
      companyLogoBase64: json['companyLogoBase64'] as String?,
      hsnNumber: json['hsnNumber'] as String?,
    );
  }
}

class AppSettings {
  String themeMode; // 'light' or 'dark'

  AppSettings({required this.themeMode});

  Map<String, dynamic> toJson() => {'themeMode': themeMode};

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final mode = (json['themeMode'] as String?) ?? 'light';
    return AppSettings(themeMode: mode == 'dark' ? 'dark' : 'light');
  }
}

class AppDataStore {
  AppDataStore._internal();

  static final AppDataStore instance = AppDataStore._internal();

  // Basic AES key (32 bytes). In a real app, manage this securely.
  // IMPORTANT: length must be 16/24/32 bytes; this is exactly 32.
  static final encrypt.Key _baseKey = encrypt.Key.fromUtf8(
    const String.fromEnvironment('APP_SECRET_KEY', defaultValue: 'lakhaan-app-secret-key-32-bytes!'),
  );

  late final encrypt.Encrypter _encrypter = encrypt.Encrypter(
    encrypt.AES(_baseKey),
  );

  Directory? _baseDir;
  late final String _username;

  Directory get baseDir {
    if (_baseDir == null) {
      throw StateError('Storage not available on web');
    }
    return _baseDir!;
  }

  // Notifier for profile changes
  final ValueNotifier<StoredProfile?> profileNotifier =
      ValueNotifier<StoredProfile?>(null);

  // In-memory data
  List<StoredInvoice> invoices = [];
  List<StoredClient> clients = [];
  StoredProfile? _profile;
  AppSettings settings = AppSettings(themeMode: 'light');

  StoredProfile? get profile => _profile;

  set profile(StoredProfile? value) {
    _profile = value;
    profileNotifier.value = value;
  }

  void clearAll() {
    profile = null;
    invoices.clear();
    clients.clear();
  }

  Future<void> init(String username) async {
    _username = username.isEmpty ? 'defaultUser' : username;

    // Check if running on web (kIsWeb from foundation)
    if (kIsWeb) {
      // For web, use in-memory storage (no local persistence)
      // Data will be lost on refresh - but Firebase auth works
      _baseDir = null;
      debugPrint('Running on web - using in-memory storage');
      return;
    }

    Directory? root;

    // Prefer system-wide /Library, but fall back to user Library if
    // permissions are insufficient.
    try {
      root = Directory('/Library/Application Support/lakhaanData');
      if (!await root.exists()) {
        await root.create(recursive: true);
      }
    } catch (_) {
      root = null;
    }

    if (root == null) {
      try {
        final home = Platform.environment['HOME'] ?? '';
        root = Directory('$home/Library/Application Support/lakhaanData');
        if (!await root.exists()) {
          await root.create(recursive: true);
        }
      } catch (_) {
        // As a last resort, use the app's current directory.
        root = Directory('lakhaanData');
        if (!await root.exists()) {
          await root.create(recursive: true);
        }
      }
    }

    _baseDir = Directory('${root.path}/$_username');
    if (!await _baseDir!.exists()) {
      await _baseDir!.create(recursive: true);
    }

    // Log the resolved data directory so you can verify it on disk.
    // This prints in the Flutter run console.
    // Example: /Library/Application Support/lakhaanData/defaultUser
    // or       /Users/you/Library/Application Support/lakhaanData/defaultUser
    // or       <app-working-dir>/lakhaanData/defaultUser
    // (depending on which path was writable).
    // ignore: avoid_print
    print('Lakhaan data directory: ${_baseDir!.path}');

    await _loadSettings();
    await _loadInvoices();
    await _loadClients();
    await _loadProfile();
  }

  Future<void> _loadInvoices() async {
    final file = File('${_baseDir!.path}/invoices.json.enc');
    if (!await file.exists()) {
      invoices = [];
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        invoices = [];
        return;
      }
      final jsonStr = _decryptToString(bytes);
      if (jsonStr == null || jsonStr.isEmpty) {
        invoices = [];
        return;
      }
      final decoded = json.decode(jsonStr);
      if (decoded is! List) {
        invoices = [];
        return;
      }
      invoices = decoded
          .whereType<Map<String, dynamic>>()
          .map((m) => StoredInvoice.fromJson(m))
          .toList();
    } catch (_) {
      invoices = [];
    }
  }

  Future<void> _loadSettings() async {
    final file = File('${_baseDir!.path}/settings.json.enc');
    if (!await file.exists()) {
      settings = AppSettings(themeMode: 'light');
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        settings = AppSettings(themeMode: 'light');
        return;
      }
      final jsonStr = _decryptToString(bytes);
      if (jsonStr == null || jsonStr.isEmpty) {
        settings = AppSettings(themeMode: 'light');
        return;
      }
      final decoded = json.decode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        settings = AppSettings(themeMode: 'light');
        return;
      }
      settings = AppSettings.fromJson(decoded);
    } catch (_) {
      settings = AppSettings(themeMode: 'light');
    }
  }

  Future<void> _loadClients() async {
    final file = File('${_baseDir!.path}/clients.json.enc');
    if (!await file.exists()) {
      clients = [];
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        clients = [];
        return;
      }
      final jsonStr = _decryptToString(bytes);
      if (jsonStr == null || jsonStr.isEmpty) {
        clients = [];
        return;
      }
      final decoded = json.decode(jsonStr);
      if (decoded is! List) {
        clients = [];
        return;
      }
      clients = decoded
          .whereType<Map<String, dynamic>>()
          .map((m) => StoredClient.fromJson(m))
          .toList();
    } catch (_) {
      clients = [];
    }
  }

  Future<void> _loadProfile() async {
    final file = File('${_baseDir!.path}/profile.json.enc');
    if (!await file.exists()) {
      profile = null;
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        profile = null;
        return;
      }
      final jsonStr = _decryptToString(bytes);
      if (jsonStr == null || jsonStr.isEmpty) {
        profile = null;
        return;
      }
      final decoded = json.decode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        profile = null;
        return;
      }
      profile = StoredProfile.fromJson(decoded);
      profileNotifier.value = _profile;
    } catch (_) {
      profile = null;
      profileNotifier.value = null;
    }
  }

  Future<void> saveInvoices() async {
    if (_baseDir == null) return;
    final file = File('${_baseDir!.path}/invoices.json.enc');
    final list = invoices.map((e) => e.toJson()).toList();
    final jsonStr = json.encode(list);
    final bytes = _encryptString(jsonStr);
    await file.writeAsBytes(bytes, flush: true);
  }

  Future<void> saveSettings() async {
    if (_baseDir == null) return;
    final file = File('${_baseDir!.path}/settings.json.enc');
    final jsonStr = json.encode(settings.toJson());
    final bytes = _encryptString(jsonStr);
    await file.writeAsBytes(bytes, flush: true);
  }

  Future<void> saveClients() async {
    if (_baseDir == null) return;
    final file = File('${_baseDir!.path}/clients.json.enc');
    final list = clients.map((e) => e.toJson()).toList();
    final jsonStr = json.encode(list);
    final bytes = _encryptString(jsonStr);
    await file.writeAsBytes(bytes, flush: true);
  }

  Future<void> saveProfile() async {
    if (_baseDir == null) return;
    final file = File('${_baseDir!.path}/profile.json.enc');
    if (profile == null) {
      if (await file.exists()) {
        await file.delete();
      }
      profileNotifier.value = null;
      return;
    }
    final jsonStr = json.encode(profile!.toJson());
    final bytes = _encryptString(jsonStr);
    await file.writeAsBytes(bytes, flush: true);
  }

  Uint8List _encryptString(String plaintext) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plaintext, iv: iv);
    final combined = <int>[...iv.bytes, ...encrypted.bytes];
    return Uint8List.fromList(combined);
  }

  String? _decryptToString(List<int> data) {
    if (data.length < 16) return null;
    final ivBytes = Uint8List.fromList(data.sublist(0, 16));
    final cipherBytes = Uint8List.fromList(data.sublist(16));
    final iv = encrypt.IV(ivBytes);
    final encrypted = encrypt.Encrypted(cipherBytes);
    try {
      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {
      return null;
    }
  }
}
