class AppUser {
  const AppUser({
    required this.name,
    required this.email,
    this.password = '',
    required this.role,
  });

  final String name;
  final String email;
  final String password;
  final String role;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      role: (map['role'] as String?) ?? 'Student',
    );
  }
}
