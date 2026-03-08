import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../navbar/navbar.dart';
import '../storage/app_data_store.dart';
import '../services/firestore_service.dart';

class GstLookupService {
  static const Map<String, String> stateCodes = {
    '01': 'Jammu and Kashmir',
    '02': 'Himachal Pradesh',
    '03': 'Punjab',
    '04': 'Chandigarh',
    '05': 'Uttarakhand',
    '06': 'Haryana',
    '07': 'Delhi',
    '08': 'Rajasthan',
    '09': 'Uttar Pradesh',
    '10': 'Bihar',
    '11': 'Sikkim',
    '12': 'Arunachal Pradesh',
    '13': 'Nagaland',
    '14': 'Manipur',
    '15': 'Mizoram',
    '16': 'Tripura',
    '17': 'Meghalaya',
    '18': 'Assam',
    '19': 'West Bengal',
    '20': 'Jharkhand',
    '21': 'Odisha',
    '22': 'Chhattisgarh',
    '23': 'Madhya Pradesh',
    '24': 'Gujarat',
    '25': 'Daman and Diu',
    '26': 'Dadra and Nagar Haveli',
    '27': 'Maharashtra',
    '28': 'Andhra Pradesh (Old)',
    '29': 'Karnataka',
    '30': 'Goa',
    '31': 'Lakshadweep',
    '32': 'Kerala',
    '33': 'Tamil Nadu',
    '34': 'Puducherry',
    '35': 'Andaman and Nicobar Islands',
    '36': 'Telangana',
    '37': 'Andhra Pradesh (New)',
  };

  // The Vercel serverless proxy URL — keeps API keys off the client.
  static const String _proxyUrl =
      'https://gst-proxy-three.vercel.app/api/verify-gst';

  static Future<Map<String, String>?> fetchGstDetails(String gstNumber) async {
    final cleanGst = gstNumber.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (cleanGst.length != 15) return null;

    try {
      final response = await http.post(
        Uri.parse(_proxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'gstin': cleanGst}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return {
            'name': data['name']?.toString() ?? '',
            'address': data['address']?.toString() ?? '',
            'city': data['city']?.toString() ?? '',
            'state': data['state']?.toString() ?? '',
            'pincode': data['pincode']?.toString() ?? '',
            'phone': data['phone']?.toString() ?? '',
            'email': data['email']?.toString() ?? '',
          };
        }
      }
      debugPrint('GST proxy failed [${response.statusCode}]: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Exception during GST fetch: $e');
      return null;
    }
  }

  static bool isValidGstFormat(String gst) {
    final cleanGst = gst.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (cleanGst.length != 15) return false;
    final stateCode = cleanGst.substring(0, 2);
    return stateCodes.containsKey(stateCode);
  }
}

class Client {
  final String id;
  String name;
  String gstNumber;
  String? panNumber;
  String address;
  String city;
  String state;
  String pincode;
  String phone;
  String email;

  Client({
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
}

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});
  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final List<Client> _clients = [];

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _loadClientsFromFirestore();
    } else {
      _loadClientsFromStore();
    }
  }

  Future<void> _loadClientsFromFirestore() async {
    final clients = await FirestoreService.instance.getClients();
    setState(() {
      _clients.clear();
      _clients.addAll(clients.map((c) => Client(
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
      )));
    });
  }

  void _loadClientsFromStore() {
    final stored = AppDataStore.instance.clients;
    if (stored.isEmpty) return;
    setState(() {
      _clients.clear();
      _clients.addAll(
        stored.map(
          (c) => Client(
            id: c.id,
            name: c.name,
            gstNumber: c.gstNumber,
            panNumber: c.panNumber,
            address: c.address,
            city: c.city,
            state: c.state,
            pincode: c.pincode,
            phone: c.phone,
            email: c.email,
          ),
        ),
      );
    });
  }

  Future<void> _persistClients() async {
    if (kIsWeb) {
      // On web, sync with Firestore
      for (final client in _clients) {
        await FirestoreService.instance.updateClient(client.id, {
          'name': client.name,
          'gstNumber': client.gstNumber,
          'panNumber': client.panNumber,
          'address': client.address,
          'city': client.city,
          'state': client.state,
          'pincode': client.pincode,
          'phone': client.phone,
          'email': client.email,
        });
      }
      return;
    }

    AppDataStore.instance.clients = _clients
        .map(
          (c) => StoredClient(
            id: c.id,
            name: c.name,
            gstNumber: c.gstNumber,
            panNumber: c.panNumber,
            address: c.address,
            city: c.city,
            state: c.state,
            pincode: c.pincode,
            phone: c.phone,
            email: c.email,
          ),
        )
        .toList();
    await AppDataStore.instance.saveClients();
  }

  Widget _buildSectionTitle(String title, ThemeData theme) => Text(
    title,
    style: theme.textTheme.titleSmall!.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.primary,
    ),
  );

  Widget _buildInputField(
    String label,
    IconData icon,
    String value,
    Function(String) onChanged, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool enabled = true,
  }) => TextFormField(
    initialValue: value,
    maxLines: maxLines,
    keyboardType: keyboardType,
    enabled: enabled,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    validator: required
        ? (v) => (v == null || v.isEmpty) ? 'Required' : null
        : null,
    onChanged: onChanged,
  );

  Future<void> _onLogout() async {
    await FirebaseAuth.instance.signOut();
    AppDataStore.instance.clearAll();
  }

  Future<void> _openClientForm({Client? editing}) async {
    final result = await showDialog<Client>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final formKey = GlobalKey<FormState>();
        String name = editing?.name ?? '';
        String gst = editing?.gstNumber ?? '';
        String panNumber = editing?.panNumber ?? '';
        String address = editing?.address ?? '';
        String city = editing?.city ?? '';
        String state = editing?.state ?? '';
        String pincode = editing?.pincode ?? '';
        String phone = editing?.phone ?? '';
        String email = editing?.email ?? '';
        bool isVerified = editing != null;
        bool isVerifying = false;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              elevation: 24,
              shadowColor: Colors.black.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 580,
                  maxHeight: 750,
                ),
                child: Column(
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
                              editing == null ? Icons.person_add : Icons.edit,
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
                                  editing == null
                                      ? 'Add New Client'
                                      : 'Edit Client',
                                  style: theme.textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  editing == null
                                      ? 'Enter GST number to auto-fetch details'
                                      : 'Update client information',
                                  style: theme.textTheme.bodySmall!.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(null),
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
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: formKey,
                          child: isVerified
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.verified,
                                            size: 20,
                                            color: theme.colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              gst.toUpperCase(),
                                              style: theme.textTheme.bodyMedium!
                                                  .copyWith(
                                                    fontFamily: 'monospace',
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                          if (editing == null)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                size: 18,
                                              ),
                                              onPressed: () => setDialogState(
                                                () => isVerified = false,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    _buildSectionTitle(
                                      'Business Details',
                                      theme,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInputField(
                                      'Business Name *',
                                      Icons.business,
                                      name,
                                      (v) => name = v,
                                      required: true,
                                      enabled: !isVerified || editing != null,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildSectionTitle('Address', theme),
                                    const SizedBox(height: 12),
                                    _buildInputField(
                                      'Address',
                                      Icons.location_on_outlined,
                                      address,
                                      (v) => address = v,
                                      maxLines: 2,
                                      enabled: !isVerified || editing != null,
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
                                            enabled: !isVerified || editing != null,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildInputField(
                                            'State',
                                            Icons.map,
                                            state,
                                            (v) => state = v,
                                            enabled: !isVerified || editing != null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInputField(
                                            'Pincode',
                                            Icons.pin_drop,
                                            pincode,
                                            (v) => pincode = v,
                                            keyboardType: TextInputType.number,
                                            enabled: !isVerified || editing != null,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildInputField(
                                            'Phone',
                                            Icons.phone,
                                            phone,
                                            (v) => phone = v,
                                            keyboardType: TextInputType.phone,
                                            enabled: !isVerified || editing != null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInputField(
                                            'PAN Number',
                                            Icons.numbers,
                                            panNumber,
                                            (v) => panNumber = v,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildInputField(
                                            'Email',
                                            Icons.email_outlined,
                                            email,
                                            (v) => email = v,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Container(
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.business_center,
                                        size: 60,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Enter GST Number',
                                        style: theme.textTheme.titleMedium!
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'We will fetch business details automatically',
                                        style: theme.textTheme.bodySmall!
                                            .copyWith(color: theme.hintColor),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          hintText: 'e.g., 27AAPFU1234A1Z5',
                                          prefixIcon: const Icon(Icons.numbers),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          filled: true,
                                        ),
                                        textCapitalization:
                                            TextCapitalization.characters,
                                        validator: (v) =>
                                            (v == null || v.isEmpty)
                                            ? 'Please enter GST number'
                                            : null,
                                        onChanged: (v) => gst = v,
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: isVerifying
                                              ? null
                                              : () async {
                                                  if (!formKey.currentState!
                                                      .validate())
                                                    return;
                                                  if (!GstLookupService.isValidGstFormat(
                                                    gst,
                                                  )) {
                                                    ScaffoldMessenger.of(
                                                      ctx,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Please enter a valid 15-digit GST number',
                                                        ),
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  setDialogState(
                                                    () => isVerifying = true,
                                                  );
                                                  final details =
                                                      await GstLookupService.fetchGstDetails(
                                                        gst,
                                                      );
                                                  setDialogState(() {
                                                    isVerifying = false;
                                                    if (details != null) {
                                                      name =
                                                          details['name'] ?? '';
                                                      address =
                                                          details['address'] ??
                                                          '';
                                                      city =
                                                          details['city'] ?? '';
                                                      state =
                                                          details['state'] ??
                                                          '';
                                                      pincode =
                                                          details['pincode'] ??
                                                          '';
                                                      phone =
                                                          details['phone'] ??
                                                          '';
                                                      email =
                                                          details['email'] ??
                                                          '';
                                                      isVerified = true;
                                                    }
                                                  });
                                                  if (details != null) {
                                                    ScaffoldMessenger.of(
                                                      ctx,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'GST details verified successfully!',
                                                        ),
                                                        backgroundColor:
                                                            Colors.green,
                                                      ),
                                                    );
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                      ctx,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Could not verify GST. Please enter details manually.',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                          icon: isVerifying
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.verified_outlined,
                                                ),
                                          label: Text(
                                            isVerifying
                                                ? 'Verifying...'
                                                : 'Verify GST',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: theme.dividerColor),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(null),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isVerified
                                  ? () {
                                      if (!formKey.currentState!.validate())
                                        return;
                                      final id =
                                          editing?.id ??
                                          DateTime.now().microsecondsSinceEpoch
                                              .toString();
                                      Navigator.of(ctx).pop(
                                        Client(
                                          id: id,
                                          name: name,
                                          gstNumber: gst,
                                          panNumber: panNumber.isEmpty
                                              ? null
                                              : panNumber,
                                          address: address,
                                          city: city,
                                          state: state,
                                          pincode: pincode,
                                          phone: phone,
                                          email: email,
                                        ),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                editing == null ? 'Add Client' : 'Save Changes',
                              ),
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

    if (result == null) return;
    bool isNewClient = editing == null;

    // On web, save to Firestore first to get ID
    if (kIsWeb && isNewClient) {
      final clientId = await FirestoreService.instance.addClient({
        'name': result.name,
        'gstNumber': result.gstNumber,
        'panNumber': result.panNumber,
        'address': result.address,
        'city': result.city,
        'state': result.state,
        'pincode': result.pincode,
        'phone': result.phone,
        'email': result.email,
      });
      final updatedClient = Client(
        id: clientId,
        name: result.name,
        gstNumber: result.gstNumber,
        panNumber: result.panNumber,
        address: result.address,
        city: result.city,
        state: result.state,
        pincode: result.pincode,
        phone: result.phone,
        email: result.email,
      );
      setState(() => _clients.add(updatedClient));
      return;
    }

    setState(() {
      if (isNewClient) {
        _clients.add(result);
      } else {
        final index = _clients.indexWhere((c) => c.id == editing.id);
        if (index != -1) _clients[index] = result;
      }
    });
    await _persistClients();
  }

  void _deleteClient(Client client) {
    setState(() => _clients.removeWhere((c) => c.id == client.id));
    if (kIsWeb) {
      FirestoreService.instance.deleteClient(client.id);
    } else {
      _persistClients();
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Client deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = AppDataStore.instance.profile;
    final displayName = (profile?.name.isNotEmpty == true
        ? profile!.name
        : 'User');

    return Scaffold(
      appBar: Navbar(
        userName: displayName,
        onLogout: _onLogout,
      ),
      drawer: NavbarDrawer(
        userName: displayName,
        onLogout: _onLogout,
      ),
      body: Container(
        color: theme.colorScheme.surface,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clients',
                            style: theme.textTheme.headlineSmall!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_clients.length} clients',
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openClientForm(),
                        icon: const Icon(
                          Icons.person_add_alt_1_outlined,
                          size: 18,
                        ),
                        label: const Text('Add Client'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _clients.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.group_add_outlined,
                                    size: 64,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'No clients added yet',
                                  style: theme.textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add your first client to start billing',
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
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: constraints.maxWidth,
                                      ),
                                      child: _buildClientTable(context, _clients),
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

  Widget _buildClientTable(BuildContext context, List<Client> clients) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Theme(
      data: theme.copyWith(
        dataTableTheme: DataTableThemeData(
          headingRowColor: MaterialStateProperty.all(
            isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          ),
          dataRowColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.hovered)) {
                return theme.colorScheme.primary.withOpacity(isDark ? 0.1 : 0.04);
              }
              return null;
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
        dataRowMinHeight: 72,
        dataRowMaxHeight: 72,
        columns: const [
          DataColumn(label: Text('Client')),
          DataColumn(label: Text('Contact Details')),
          DataColumn(label: Text('Location')),
          DataColumn(label: Text('Tax Info')),
          DataColumn(
            label: Align(alignment: Alignment.centerRight, child: Text('Actions')),
          ),
        ],
        rows: clients.map((client) {
          return DataRow(
            cells: [
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (client.email.isNotEmpty)
                          Text(
                            client.email,
                            style: TextStyle(color: theme.hintColor, fontSize: 13),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.phone.isNotEmpty ? client.phone : 'No Phone'),
                    if (client.email.isNotEmpty)
                      Text(
                        'Primary Contact',
                        style: TextStyle(color: theme.hintColor, fontSize: 12),
                      ),
                  ],
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${client.city}, ${client.state}'),
                    Text(
                      client.pincode,
                      style: TextStyle(color: theme.hintColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.gstNumber,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (client.panNumber?.isNotEmpty == true)
                      Text(
                        'PAN: ${client.panNumber}',
                        style: TextStyle(color: theme.hintColor, fontSize: 12),
                      ),
                  ],
                ),
              ),
              DataCell(
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit Client',
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        color: theme.hintColor,
                        onPressed: () => _openClientForm(editing: client),
                      ),
                      IconButton(
                        tooltip: 'Delete Client',
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: theme.colorScheme.error,
                        onPressed: () => _deleteClient(client),
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
} // End of client_screen.dart
