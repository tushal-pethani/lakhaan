import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUserProfile {
  final String uid;
  final String email;
  final String name;
  final String gstNumber;

  const AppUserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.gstNumber,
  });

  factory AppUserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return AppUserProfile(
      uid: uid,
      email: (data['email'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      gstNumber: (data['gstNumber'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'name': name,
        'gstNumber': gstNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String emailKey(String email) => Uri.encodeComponent(email.trim().toLowerCase());

  Future<AppUserProfile> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String gstNumber,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'User creation failed.',
      );
    }

    final profile = AppUserProfile(
      uid: user.uid,
      email: (user.email ?? email).trim(),
      name: name.trim(),
      gstNumber: gstNumber.trim(),
    );

    await _db.collection('users').doc(user.uid).set(
          {
            ...profile.toFirestore(),
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

    return profile;
  }

  Future<AppUserProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Sign in failed.',
      );
    }

    final doc = await _db.collection('users').doc(user.uid).get();
    final data = doc.data() ?? <String, dynamic>{};

    // Ensure at least email is stored.
    if (!doc.exists || (data['email'] as String?)?.isEmpty != false) {
      await _db.collection('users').doc(user.uid).set(
        {
          'email': user.email ?? email.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    return AppUserProfile.fromFirestore(
      user.uid,
      {
        'email': user.email ?? email.trim(),
        ...data,
      },
    );
  }

  Future<void> signOut() => _auth.signOut();
}

