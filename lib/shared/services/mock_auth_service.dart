import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pre_order_system/app/routes.dart';
import 'package:pre_order_system/shared/models/app_user.dart';

class MockAuthService {
  MockAuthService._();

  static final MockAuthService instance = MockAuthService._();
  static const String roleAdmin = 'admin';
  static const String roleStudent = 'student';
  static const String roleFaculty = 'faculty';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _currentUser;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  AppUser? get currentUser => _currentUser;

  String? get currentUserRoleKey {
    final role = _currentUser?.role;
    if (role == null) {
      return null;
    }
    return _normalizeRole(role);
  }

  bool get canManageMenuAndViewAllOrders => currentUserRoleKey == roleAdmin;

  bool get canPlaceOrderAndViewOwnHistory {
    final role = currentUserRoleKey;
    return role == roleStudent || role == roleFaculty;
  }

  String get postLoginRoute {
    return canManageMenuAndViewAllOrders ? AppRoutes.admin : AppRoutes.dashboard;
  }

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
    final roleKey = _normalizeRole(role);
    final roleLabel = _toDisplayRole(roleKey);

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
        'role': roleKey,
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
        role: roleLabel,
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
        final roleKey = await fetchUserRoleFromFirestore(user.uid);
        final profile = await _readProfile(user, forcedRoleKey: roleKey);
        _currentUser = profile;
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
    final roleKey = _normalizeRole(newRole);
    final roleLabel = _toDisplayRole(roleKey);

    if (_currentUser?.email == normalizedEmail) {
      final user = _currentUser!;
      _currentUser = AppUser(
        name: user.name,
        email: user.email,
        password: user.password,
        role: roleLabel,
      );
    }

    unawaited(_updateRoleByEmail(normalizedEmail, roleKey));
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

  Future<String> fetchUserRoleFromFirestore(String uid) async {
    final profileDoc = await _usersCollection.doc(uid).get();
    final profile = profileDoc.data();
    final storedRole = (profile?['role'] as String?) ?? roleStudent;
    return _normalizeRole(storedRole);
  }

  Future<AppUser> _readProfile(User firebaseUser, {String? forcedRoleKey}) async {
    final profileDoc = await _usersCollection.doc(firebaseUser.uid).get();
    final profile = profileDoc.data();

    final email = firebaseUser.email ?? '';
    final roleKey = forcedRoleKey ?? _normalizeRole((profile?['role'] as String?) ?? roleStudent);
    final name = (profile?['name'] as String?) ??
        (firebaseUser.displayName?.trim().isNotEmpty == true
            ? firebaseUser.displayName!.trim()
            : 'User');

    return AppUser(
      name: name,
      email: email,
      password: '',
      role: _toDisplayRole(roleKey),
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
      role: _toDisplayRole(roleStudent),
    );
  }

  String _normalizeRole(String role) {
    final normalized = role.trim().toLowerCase();
    if (normalized == roleAdmin) {
      return roleAdmin;
    }
    if (normalized == roleFaculty) {
      return roleFaculty;
    }
    return roleStudent;
  }

  String _toDisplayRole(String role) {
    switch (role) {
      case roleAdmin:
        return 'Admin';
      case roleFaculty:
        return 'Faculty';
      default:
        return 'Student';
    }
  }

  void dispose() {}
}
 