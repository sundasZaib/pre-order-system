import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pre_order_system/shared/models/app_user.dart';

class MockAuthService {
  MockAuthService._();

  static final MockAuthService instance = MockAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _currentUser;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  AppUser? get currentUser => _currentUser;

  Future<void> restoreSession() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      _currentUser = null;
      return;
    }

    try {
      _currentUser = await _readProfile(firebaseUser);
    } on FirebaseException {
      _currentUser = _buildFallbackUser(firebaseUser);
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return false;
      }

      await user.updateDisplayName(name.trim());

      final profile = {
        'name': name.trim(),
        'email': normalizedEmail,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      };

      try {
        await _usersCollection.doc(user.uid).set(profile);
      } on FirebaseException {
        // Keep the auth account usable even if Firestore is unavailable.
      }

      _currentUser = AppUser(
        name: name.trim(),
        email: normalizedEmail,
        password: '',
        role: role,
      );

      return true;
    } on FirebaseAuthException {
      return false;
    } on FirebaseException {
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return false;
      }

      try {
        _currentUser = await _readProfile(user);
      } on FirebaseException {
        _currentUser = _buildFallbackUser(user);
      }

      return true;
    } on FirebaseAuthException {
      return false;
    } on FirebaseException {
      return false;
    }
  }

  void logout() {
    unawaited(_auth.signOut());
    _currentUser = null;
  }

  void updateUserRole(String email, String newRole) {
    final normalizedEmail = email.trim().toLowerCase();

    if (_currentUser?.email == normalizedEmail) {
      final user = _currentUser!;
      _currentUser = AppUser(
        name: user.name,
        email: user.email,
        password: user.password,
        role: newRole,
      );
    }

    unawaited(_updateRoleByEmail(normalizedEmail, newRole));
  }

  Future<void> updateUserName(String newName) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty || _currentUser == null) {
      return;
    }

    _currentUser = AppUser(
      name: trimmedName,
      email: _currentUser!.email,
      password: _currentUser!.password,
      role: _currentUser!.role,
    );

    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      return;
    }

    await firebaseUser.updateDisplayName(trimmedName);
    await _usersCollection.doc(firebaseUser.uid).update({'name': trimmedName});
  }

  Future<AppUser> _readProfile(User firebaseUser) async {
    final profileDoc = await _usersCollection.doc(firebaseUser.uid).get();
    final profile = profileDoc.data();

    final email = firebaseUser.email ?? '';
    final role = (profile?['role'] as String?) ?? 'Student';
    final name = (profile?['name'] as String?) ??
        (firebaseUser.displayName?.trim().isNotEmpty == true
            ? firebaseUser.displayName!.trim()
            : 'User');

    return AppUser(
      name: name,
      email: email,
      password: '',
      role: role,
    );
  }

  Future<void> _updateRoleByEmail(String email, String newRole) async {
    QuerySnapshot<Map<String, dynamic>> query;

    try {
      query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
    } on FirebaseException {
      return;
    }

    if (query.docs.isEmpty) {
      return;
    }

    await query.docs.first.reference.update({'role': newRole});
  }

  AppUser _buildFallbackUser(User firebaseUser) {
    final email = (firebaseUser.email ?? '').trim().toLowerCase();
    final guessedName = (firebaseUser.displayName ?? '').trim();

    return AppUser(
      name: guessedName.isEmpty ? 'User' : guessedName,
      email: email,
      password: '',
      role: 'Student',
    );
  }

  void dispose() {}
}
 