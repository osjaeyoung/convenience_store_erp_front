/// 급여명세 화면용 숫자·시간 표시
class PayrollFormatters {
  PayrollFormatters._();

  static String _commaInt(int n) {
    final neg = n < 0;
    final s = n.abs().toString();
    final buf = StringBuffer();
    final len = s.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return neg ? '-$buf' : buf.toString();
  }

  static String krw(num? value) {
    if (value == null) return '-';
    return '${_commaInt(value.round())}원';
  }

  static String krwInt(int? value) {
    if (value == null) return '-';
    return '${_commaInt(value)}원';
  }

  /// 총 근무시간(분) → "N시간" (정수 시간으로 표시)
  static String hoursFromMinutes(int? minutes) {
    if (minutes == null || minutes <= 0) return '-';
    final h = (minutes / 60).round();
    return '$h시간';
  }

  static int? parseDigits(String text) {
    final s = text.replaceAll(RegExp(r'[^\d]'), '');
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  static List<Map<String, dynamic>> parseItemList(Map<String, dynamic>? raw) {
    if (raw == null) return [];
    final items = raw['items'] ?? raw['payroll_statements'];
    if (items is! List) return [];
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static void sortPayrollItems(List<Map<String, dynamic>> items) {
    items.sort((a, b) {
      final ya = (a['year'] as num?)?.toInt() ?? 0;
      final yb = (b['year'] as num?)?.toInt() ?? 0;
      if (ya != yb) return yb.compareTo(ya);
      final ma = (a['month'] as num?)?.toInt() ?? 0;
      final mb = (b['month'] as num?)?.toInt() ?? 0;
      return mb.compareTo(ma);
    });
  }
}
