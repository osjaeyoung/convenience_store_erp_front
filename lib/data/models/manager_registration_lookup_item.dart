class ManagerRegistrationLookupItem {
  const ManagerRegistrationLookupItem({
    required this.registrationId,
    required this.branchId,
    required this.branchName,
    this.branchCode,
    this.registrationStatus,
    this.linkedUserId,
  });

  final int registrationId;
  final int branchId;
  final String branchName;
  final String? branchCode;
  final String? registrationStatus;
  final int? linkedUserId;

  factory ManagerRegistrationLookupItem.fromJson(Map<String, dynamic> json) {
    return ManagerRegistrationLookupItem(
      registrationId: json['registration_id'] as int,
      branchId: json['branch_id'] as int,
      branchName: json['branch_name'] as String,
      branchCode: json['branch_code'] as String?,
      registrationStatus: json['registration_status'] as String?,
      linkedUserId: json['linked_user_id'] as int?,
    );
  }
}
