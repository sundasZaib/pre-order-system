import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pre_order_system/shared/models/app_user.dart';

class MockAuthService {
  MockAuthService._();

  static final MockAuthService instance = MockAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;

  AppUser? _currentUser;
  bool _initialized = false;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  AppUser? get currentUser {
    _ensureInitialized();
    final firebaseUser = _auth.currentUser;
    if (_currentUser == null && firebaseUser != null) {
      unawaited(_syncCurrentUserFromFirestore(firebaseUser.uid));
    }
    return _currentUser;
  }

  void _ensureInitialized() {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _authSubscription = _auth.authStateChanges().listen((firebaseUser) {
      if (firebaseUser == null) {
        _currentUser = null;
        return;
      }

      _syncCurrentUserFromFirestore(firebaseUser.uid);
    });
  }

  Future<void> _syncCurrentUserFromFirestore(String uid) async {
    try {
      final snapshot = await _usersCollection.doc(uid).get();
      if (!snapshot.exists) {
        final firebaseUser = _auth.currentUser;
        if (firebaseUser == null) {
          return;
        }

        _currentUser = AppUser(
          name: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          role: 'Student',
        );
        return;
      }

      _currentUser = AppUser.fromMap(snapshot.data()!);
    } catch (_) {
      // Keep local state untouched on transient backend failures.
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _ensureInitialized();

    final normalizedEmail = email.trim().toLowerCase();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      await credential.user?.updateDisplayName(name.trim());

      final newUser = AppUser(
        name: name.trim(),
        email: normalizedEmail,
        role: role,
      );

      await _usersCollection.doc(credential.user!.uid).set(newUser.toMap());
      _currentUser = newUser;
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _ensureInitialized();
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      await _syncCurrentUserFromFirestore(credential.user!.uid);
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  void logout() {
    _ensureInitialized();
    unawaited(_auth.signOut());
    _currentUser = null;
  }

  void updateUserRole(String email, String newRole) {
    _ensureInitialized();
    final normalizedEmail = email.trim().toLowerCase();

    if (_currentUser == null || _currentUser!.email != normalizedEmail) {
      return;
    }

    _currentUser = AppUser(
      name: _currentUser!.name,
      email: _currentUser!.email,
      role: newRole,
    );

    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      unawaited(_usersCollection.doc(uid).update({'role': newRole}));
    }
  }

  Future<void> updateUserName(String newName) async {
    _ensureInitialized();

    final trimmedName = newName.trim();
    if (trimmedName.isEmpty || _currentUser == null) {
      return;
    }

    _currentUser = AppUser(
      name: trimmedName,
      email: _currentUser!.email,
      role: _currentUser!.role,
    );

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return;
    }

    await _auth.currentUser?.updateDisplayName(trimmedName);
    await _usersCollection.doc(uid).update({'name': trimmedName});
  }

  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
    _initialized = false;
  }
}
