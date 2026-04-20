import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../auth/widgets/auth_input_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

class AccountFieldSection extends StatelessWidget {
  const AccountFieldSection({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMediumM.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        child,
      ],
    );
  }
}

class AccountGreyFieldContainer extends StatelessWidget {
  const AccountGreyFieldContainer({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.grey0Alt,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: child,
    );
  }
}

class AccountGreyTextField extends StatelessWidget {
  const AccountGreyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.onChanged,
    this.readOnly = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AuthInputField(
      controller: controller,
      hintText: hintText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      readOnly: readOnly,
      enabled: enabled,
      fillColor: AppColors.grey0Alt,
      focusedBorderColor: AppColors.grey50,
      hintStyle: AppTypography.bodyMediumR.copyWith(
        color: AppColors.textDisabled,
      ),
    );
  }
}

class AccountGreySelectField extends StatelessWidget {
  const AccountGreySelectField({
    super.key,
    required this.label,
    required this.hasValue,
    required this.onTap,
    this.showArrow = true,
  });

  final String label;
  final bool hasValue;
  final VoidCallback onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: AccountGreyFieldContainer(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMediumR.copyWith(
                    color: hasValue
                        ? AppColors.textPrimary
                        : AppColors.textDisabled,
                  ),
                ),
              ),
              if (showArrow)
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountGreyActionField extends StatelessWidget {
  const AccountGreyActionField({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.actionLabel,
    required this.onActionTap,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.onChanged,
    this.readOnly = false,
    this.enabled = true,
    this.actionLoading = false,
    this.actionColor,
  });

  final TextEditingController controller;
  final String placeholder;
  final String actionLabel;
  final VoidCallback onActionTap;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final bool enabled;
  final bool actionLoading;
  final Color? actionColor;

  @override
  Widget build(BuildContext context) {
    return AuthInputField(
      controller: controller,
      hintText: placeholder,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      readOnly: readOnly,
      enabled: enabled,
      fillColor: AppColors.grey0Alt,
      focusedBorderColor: AppColors.primary,
      contentPadding: EdgeInsets.fromLTRB(16.w, 14.h, 12.w, 14.h),
      textStyle: AppTypography.bodyMediumR.copyWith(
        color: AppColors.textPrimary,
        height: 19 / 14,
      ),
      hintStyle: AppTypography.bodyMediumR.copyWith(
        color: AppColors.textDisabled,
      ),
      suffixIconConstraints: BoxConstraints(
        minHeight: 0,
        minWidth: 88.w,
      ),
      suffix: Padding(
        padding: EdgeInsets.only(right: 6.w),
        child: SizedBox(
          width: 76.w,
          height: 28.h,
          child: Center(
            child: GestureDetector(
              onTap: (!enabled || actionLoading) ? null : onActionTap,
              child: Container(
                width: 76.w,
                height: 28.h,
                decoration: BoxDecoration(
                  color: actionColor ?? AppColors.primary,
                  borderRadius: BorderRadius.circular(8.r),
                  border: actionColor == AppColors.grey0
                      ? Border.all(color: AppColors.primary)
                      : null,
                ),
                alignment: Alignment.center,
                child: actionLoading
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.grey0,
                        ),
                      )
                    : Text(
                        actionLabel,
                        style: AppTypography.bodyMediumB.copyWith(
                          color: actionColor == AppColors.grey0
                              ? AppColors.primary
                              : AppColors.grey0,
                          fontSize: 11.sp,
                          height: 1,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
