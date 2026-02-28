import 'package:pre_order_system/shared/models/app_user.dart';

class MockAuthService {
  MockAuthService._();

  static final MockAuthService instance = MockAuthService._();

  final List<AppUser> _users = [
    const AppUser(
      name: 'Ali Raza',
      email: 'ali@student.pk',
      password: '123456',
      role: 'Student',
    ),
    const AppUser(
      name: 'Sara Khan',
      email: 'sara@faculty.pk',
      password: '123456',
      role: 'Faculty',
    ),
  ];

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  bool signup({
    required String name,
    required String email,
    required String password,
    required String role,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    final userExists = _users.any((user) => user.email == normalizedEmail);
    if (userExists) {
      return false;
    }

    final newUser = AppUser(
      name: name.trim(),
      email: normalizedEmail,
      password: password,
      role: role,
    );

    _users.add(newUser);
    _currentUser = newUser;
    return true;
  }

  bool login({required String email, required String password}) {
    final normalizedEmail = email.trim().toLowerCase();

    for (final user in _users) {
      if (user.email == normalizedEmail && user.password == password) {
        _currentUser = user;
        return true;
      }
    }

    return false;
  }

  void logout() {
    _currentUser = null;
  }
}
