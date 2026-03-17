import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

class AuthInputField extends StatelessWidget {
  const AuthInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.prefixIconPath,
    this.prefixIconWidget,
    this.suffix,
    this.focusedBorderColor = AppColors.primary,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final AutovalidateMode autovalidateMode;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final String? prefixIconPath;
  final Widget? prefixIconWidget;
  final Widget? suffix;
  final Color focusedBorderColor;

  static const Color _errorColor = Color(0xFFFF4834);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      autovalidateMode: autovalidateMode,
      onChanged: onChanged,
      style: AppTypography.bodyMediumR.copyWith(
        color: AppColors.textPrimary,
        height: 19 / 14,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.bodyMediumR.copyWith(
          color: AppColors.grey100,
          height: 19 / 14,
        ),
        filled: true,
        fillColor: AppColors.grey0Alt,
        contentPadding: const EdgeInsets.all(16),
        prefixIcon: prefixIconWidget ??
            (prefixIconPath == null
                ? null
                : Padding(
                    padding: const EdgeInsets.all(14),
                    child: Image.asset(prefixIconPath!, width: 18, height: 18),
                  )),
        prefixIconConstraints:
            (prefixIconPath == null && prefixIconWidget == null)
                ? null
                : const BoxConstraints(minWidth: 52),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey50),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: focusedBorderColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorColor),
        ),
        errorMaxLines: 2,
        errorStyle: AppTypography.bodySmallR.copyWith(
          color: _errorColor,
          height: 18 / 12,
        ),
      ),
    );
  }
}
