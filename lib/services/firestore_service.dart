import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._();
  FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  // ============ PROFILE ============
  
  Future<Map<String, dynamic>?> getProfile() async {
    if (userId == null) return null;
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<void> saveProfile(Map<String, dynamic> profile) async {
    if (userId == null) return;
    await _db.collection('users').doc(userId).set(profile, SetOptions(merge: true));
  }

  // ============ CLIENTS ============

  Stream<List<Map<String, dynamic>>> watchClients() {
    return _db.collection('users').doc(userId).collection('clients')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    final snap = await _db.collection('users').doc(userId).collection('clients').get();
    return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<String> addClient(Map<String, dynamic> client) async {
    final docRef = await _db.collection('users').doc(userId).collection('clients').add(client);
    _incrementClientCount();
    return docRef.id;
  }

  Future<void> updateClient(String clientId, Map<String, dynamic> client) async {
    await _db.collection('users').doc(userId).collection('clients').doc(clientId).update(client);
  }

  Future<void> deleteClient(String clientId) async {
    await _db.collection('users').doc(userId).collection('clients').doc(clientId).delete();
  }

  // ============ INVOICES ============

  Stream<List<Map<String, dynamic>>> watchInvoices() {
    return _db.collection('users').doc(userId).collection('invoices')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<List<Map<String, dynamic>>> getInvoices() async {
    final snap = await _db.collection('users').doc(userId).collection('invoices').get();
    return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<String> addInvoice(Map<String, dynamic> invoice) async {
    final docRef = await _db.collection('users').doc(userId).collection('invoices').add(invoice);
    return docRef.id;
  }

  Future<void> updateInvoice(String invoiceId, Map<String, dynamic> invoice) async {
    await _db.collection('users').doc(userId).collection('invoices').doc(invoiceId).update(invoice);
  }

  Future<void> deleteInvoice(String invoiceId) async {
    await _db.collection('users').doc(userId).collection('invoices').doc(invoiceId).delete();
  }

  // ============ ANALYTICS ============

  Future<void> _incrementClientCount() async {
    String today = DateTime.now().toIso8601String().split('T')[0];
    
    DocumentReference docRef = _db.collection('analytics').doc('client_additions');

    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(docRef);
      
      Map<String, dynamic>? data = snapshot.exists ? snapshot.data() as Map<String, dynamic>? : null;
      int currentCount = data?[today] ?? 0;
      
      transaction.set(docRef, {
        today: currentCount + 1,
        'lastUpdated': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    });
  }

  static Future<Map<String, int>> getClientAnalytics() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('analytics')
        .doc('client_additions')
        .get();

    if (!snapshot.exists) return {};

    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    Map<String, int> analytics = {};

    for (var entry in data.entries) {
      if (entry.key != 'lastUpdated' && entry.value is int) {
        analytics[entry.key] = entry.value as int;
      }
    }

    return analytics;
  }
}
