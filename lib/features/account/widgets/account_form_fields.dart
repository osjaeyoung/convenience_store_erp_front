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
      focusedBorderColor: AppColors.grey50,
      contentPadding: EdgeInsets.fromLTRB(16.w, 14.h, 12.w, 14.h),
      hintStyle: AppTypography.bodyMediumR.copyWith(
        color: AppColors.textDisabled,
      ),
      suffixIconConstraints: BoxConstraints(minWidth: 63.w),
      suffix: Padding(
        padding: EdgeInsets.only(right: 12.w),
        child: SizedBox(
          height: 24.h,
          child: TextButton(
            onPressed: enabled ? onActionTap : null,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.grey0,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 0),
              minimumSize: Size(43.w, 24.h),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            child: Text(
              actionLabel,
              style: AppTypography.bodySmallB.copyWith(
                color: AppColors.grey0,
                height: 16 / 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
