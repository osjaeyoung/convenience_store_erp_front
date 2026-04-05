import 'package:flutter/widgets.dart';

/// [JobSeekerMainScreen]이 마운트되는 동안 등록한다.
/// 로고 탭 시 루트까지 pop 후 채용정보(탭 0)로 이동한다.
class JobSeekerLogoNavigation {
  JobSeekerLogoNavigation._();

  static VoidCallback? _handler;

  static void register(VoidCallback onLogoTap) {
    _handler = onLogoTap;
  }

  static void unregister(VoidCallback onLogoTap) {
    if (_handler == onLogoTap) _handler = null;
  }

  /// 등록된 메인 화면에서 처리했으면 true.
  static bool tryHandle() {
    final h = _handler;
    if (h == null) return false;
    h();
    return true;
  }
}

/// [ManagerMainScreen]이 마운트되는 동안 등록한다.
/// 로고 탭 시 루트까지 pop 후 홈(바텀 탭 0)으로 이동한다.
class ManagerLogoNavigation {
  ManagerLogoNavigation._();

  static VoidCallback? _handler;

  static void register(VoidCallback onLogoTap) {
    _handler = onLogoTap;
  }

  static void unregister(VoidCallback onLogoTap) {
    if (_handler == onLogoTap) _handler = null;
  }

  static bool tryHandle() {
    final h = _handler;
    if (h == null) return false;
    h();
    return true;
  }
}
