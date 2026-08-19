enum UserRole { customer, cashier, admin }

class AppUser {
  final String id;
  final String name;
  final String email;
  final String pin;
  final UserRole role;
  final String? authProvider; // 'email', 'google', 'facebook', 'apple'

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.pin,
    required this.role,
    this.authProvider = 'email',
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isCashier => role == UserRole.cashier;
  bool get isCustomer => role == UserRole.customer;

  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'Admin Manager';
      case UserRole.cashier:
        return 'POS Cashier';
      case UserRole.customer:
        return 'Online Customer';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'pin': pin,
      'role': role.name,
      'authProvider': authProvider,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      name: map['name'] ?? 'User',
      email: map['email'] ?? '',
      pin: map['pin'] ?? '0000',
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.customer,
      ),
      authProvider: map['authProvider'] ?? 'email',
    );
  }
}
