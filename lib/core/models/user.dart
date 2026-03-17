import '../enums/user_role.dart';

/// 앱 사용자 모델
class User {
  const User({
    required this.id,
    required this.email,
    required this.role,
    this.name,
  });

  final String id;
  final String email;
  final UserRole role;
  final String? name;

  User copyWith({
    String? id,
    String? email,
    UserRole? role,
    String? name,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
    );
  }
}
