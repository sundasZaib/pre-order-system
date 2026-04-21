import 'package:pre_order_system/shared/models/app_user.dart';

class MockAuthService {
  MockAuthService._();

  static final MockAuthService instance = MockAuthService._();

  final List<AppUser> _users = [
    AppUser(
      name: 'Ali Raza',
      email: 'ali@student.pk',
      password: '123456',
      role: 'Student',
    ),
    AppUser(
      name: 'Sara Khan',
      email: 'sara@faculty.pk',
      password: '123456',
      role: 'Faculty',
    ),
    AppUser(
      name: 'Admin User',
      email: 'admin@canteen.pk',
      password: '123456',
      role: 'Admin',
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

  void updateUserRole(String email, String newRole) {
    final normalizedEmail = email.trim().toLowerCase();
    final userIndex = _users.indexWhere((user) => user.email == normalizedEmail);
    
    if (userIndex != -1) {
      final user = _users[userIndex];
      _users[userIndex] = AppUser(
        name: user.name,
        email: user.email,
        password: user.password,
        role: newRole,
      );
      
      // Update current user if it's the same user
      if (_currentUser?.email == normalizedEmail) {
        _currentUser = _users[userIndex];
      }
    }
  }
}
