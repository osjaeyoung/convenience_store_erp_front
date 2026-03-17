/// 사용자 역할
/// - manager: 경영자
/// - storeManager: 점장
/// - jobSeeker: 구직자
enum UserRole {
  manager('경영자'),
  storeManager('점장'),
  jobSeeker('구직자');

  const UserRole(this.label);

  final String label;

  /// 경영자/점장: 바텀바 네비게이션 사용
  bool get hasBottomBar => this == manager || this == storeManager;

  /// 구직자: 전혀 다른 화면 구조
  bool get isJobSeeker => this == jobSeeker;
}
