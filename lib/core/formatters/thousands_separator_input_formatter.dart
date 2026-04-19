import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// 금액(원) 입력: 숫자만 받고 3자리마다 `,` 표시.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final n = int.tryParse(digitsOnly);
    if (n == null) return oldValue;
    final formatted = NumberFormat('#,###', 'ko_KR').format(n);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
