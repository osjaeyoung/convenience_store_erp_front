import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

class AuthInputField extends StatelessWidget {
  const AuthInputField({
    super.key,
    this.formFieldKey,
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
    this.suffixText,
    this.focusNode,
    this.inputFormatters,
    this.readOnly = false,
    this.fillColor,
    this.contentPadding,
    this.focusedBorderColor = AppColors.primary,
    this.enabled = true,
    this.minLines,
    this.maxLines = 1,
    this.hintStyle,
  });

  final GlobalKey<FormFieldState<String>>? formFieldKey;
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
  final String? suffixText;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;
  final Color focusedBorderColor;
  final bool enabled;
  final int? minLines;
  final int? maxLines;
  final TextStyle? hintStyle;

  static const Color _errorColor = Color(0xFFFF4834);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: formFieldKey,
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      autovalidateMode: autovalidateMode,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      minLines: minLines,
      maxLines: maxLines,
      style: AppTypography.bodyMediumR.copyWith(
        color: AppColors.textPrimary,
        height: 19 / 14,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: hintStyle ??
            AppTypography.bodyMediumR.copyWith(
              color: AppColors.grey100,
              height: 19 / 14,
            ),
        filled: true,
        fillColor: fillColor ?? AppColors.grey0Alt,
        contentPadding:
            contentPadding ?? const EdgeInsets.all(16),
        suffixText: suffixText,
        suffixStyle: AppTypography.bodyMediumR.copyWith(
          color: AppColors.textSecondary,
          height: 19 / 14,
        ),
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
