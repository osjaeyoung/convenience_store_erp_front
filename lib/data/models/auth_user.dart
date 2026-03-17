import '../../core/enums/user_role.dart';

/// API 응답용 사용자 모델
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.role,
    this.signupStep,
    this.approvalStatus,
    this.isActive = true,
    this.createdAt,
    this.requestedBranchId,
  });

  final int id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? role; // "owner" | "manager" | "worker"
  final String? signupStep;
  final String? approvalStatus;
  final bool isActive;
  final String? createdAt;
  final int? requestedBranchId;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] as String?,
      signupStep: json['signup_step'] as String?,
      approvalStatus: json['approval_status'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
      requestedBranchId: json['requested_branch_id'] as int?,
    );
  }

  /// API role → 앱 UserRole
  UserRole? get appRole {
    switch (role) {
      case 'owner':
        return UserRole.manager;
      case 'manager':
        return UserRole.storeManager;
      case 'worker':
        return UserRole.jobSeeker;
      default:
        return null;
    }
  }
}
