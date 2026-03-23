import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../../auth/widgets/auth_input_field.dart';

/// 포커스가 빠질 때 `validator`를 한 번 실행하는 [AuthInputField] 래퍼.
class ValidatedAuthInputField extends StatefulWidget {
  const ValidatedAuthInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.inputFormatters,
    this.readOnly = false,
    this.fillColor,
    this.suffixText,
    this.focusNode,
    this.contentPadding,
    this.prefixIconWidget,
    this.suffix,
    this.focusedBorderColor = AppColors.primary,
    this.hintStyle,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final Color? fillColor;
  final String? suffixText;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;
  final Widget? prefixIconWidget;
  final Widget? suffix;
  final Color focusedBorderColor;
  final TextStyle? hintStyle;

  @override
  State<ValidatedAuthInputField> createState() =>
      _ValidatedAuthInputFieldState();
}

class _ValidatedAuthInputFieldState extends State<ValidatedAuthInputField> {
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;
  final GlobalKey<FormFieldState<String>> _fieldKey =
      GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocus);
  }

  void _handleFocus() {
    if (!_focusNode.hasFocus) {
      _fieldKey.currentState?.validate();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthInputField(
      formFieldKey: _fieldKey,
      focusNode: _focusNode,
      controller: widget.controller,
      hintText: widget.hintText,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.disabled,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      onChanged: widget.onChanged,
      inputFormatters: widget.inputFormatters,
      readOnly: widget.readOnly,
      fillColor: widget.fillColor,
      suffixText: widget.suffixText,
      contentPadding: widget.contentPadding,
      prefixIconWidget: widget.prefixIconWidget,
      suffix: widget.suffix,
      focusedBorderColor: widget.focusedBorderColor,
      hintStyle: widget.hintStyle,
    );
  }
}
