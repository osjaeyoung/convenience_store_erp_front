/// 지점 검색 결과
class Branch {
  const Branch({
    required this.id,
    required this.name,
    this.code,
    this.ownerUserId,
  });

  final int id;
  final String name;
  final String? code;
  final int? ownerUserId;

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
      ownerUserId: json['owner_user_id'] as int?,
    );
  }
}
