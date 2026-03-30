import 'package:intl/intl.dart';

/// 인건비 화면 표시용 포맷
class LaborCostFormatters {
  LaborCostFormatters._();

  static final NumberFormat _won = NumberFormat('#,###', 'ko_KR');

  static String won(int amount) => '${_won.format(amount)}원';

  /// `+10.5%` / `-3.2%`
  static String signedPercent(double rate) {
    final sign = rate > 0 ? '+' : '';
    return '$sign${rate.toStringAsFixed(1)}%';
  }

  /// 전월 대비 지수(%) — Figma "전월 대비 총 110.3% 올랐어요"
  static String indexPercentVsPrevious(int current, int previous) {
    if (previous <= 0) return '—';
    final v = 100.0 * current / previous;
    return '${v.toStringAsFixed(1)}%';
  }

  static String monthLabel(String yyyyMm) {
    final parts = yyyyMm.split('-');
    if (parts.length != 2) return yyyyMm;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (y == null || m == null) return yyyyMm;
    return '$y년 $m월';
  }

  static String periodYearMonth(int year, int month) =>
      '$year.${month.toString().padLeft(2, '0')}';

  static String workMinutesLabel(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) {
      return '$h시간 $m분';
    }
    if (h > 0) {
      return '$h시간';
    }
    return '$m분';
  }
}
