import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/app_colors.dart';

/// 직원 프로필 박스 - 직원 상세, 리뷰 작성 등 여러 화면에서 공통 사용
///
/// [name] 근무자명
/// [hireDate] 입사일 (YYYY.MM.DD 또는 YYYY-MM-DD 형식)
/// [contact] 연락처
/// [resignationDate] 퇴사일 (퇴사자만, null이면 미표시)
/// [showEditButton] 수정 버튼 표시 여부
/// [onEditTap] 수정 버튼 탭 콜백
/// [profileImageUrl] 프로필 이미지 URL (null이면 기본 placeholder)
/// [starCount] 이름 옆 별 개수 (0~3, null이면 표시 안 함)
/// [isEditMode] 수정 모드 시 입사일만 Input으로 표시
/// [hireDateInputWidget] 수정 모드일 때 입사일 행에 표시할 위젯
class EmployeeProfileBox extends StatelessWidget {
  const EmployeeProfileBox({
    super.key,
    required this.name,
    required this.hireDate,
    required this.contact,
    this.resignationDate,
    this.showEditButton = true,
    this.onEditTap,
    this.profileImageUrl,
    this.starCount,
    this.isEditMode = false,
    this.hireDateInputWidget,
  });

  final String name;
  final String hireDate;
  final String contact;
  final String? resignationDate;
  final bool showEditButton;
  final VoidCallback? onEditTap;
  final String? profileImageUrl;
  final int? starCount;
  final bool isEditMode;
  final Widget? hireDateInputWidget;

  /// hireDate를 YYYY.MM.DD 형식으로 변환
  static String _formatDate(String raw) {
    if (raw.isEmpty) return '-';
    final parts = raw.split(RegExp(r'[-./]'));
    if (parts.length >= 3) {
      final y = parts[0];
      final m = parts[1].padLeft(2, '0');
      final d = parts[2].padLeft(2, '0');
      return '$y.$m.$d';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final formattedHire = _formatDate(hireDate);
    final formattedResign = resignationDate != null
        ? _formatDate(resignationDate!)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9FEDD4),
            Color(0xFFE1F0B8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D1D1F).withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileImage(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoRow('근무자명', _buildNameValue()),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      '입사일',
                      isEditMode && hireDateInputWidget != null
                          ? hireDateInputWidget!
                          : Text(formattedHire, style: _valueStyle),
                    ),
                    if (formattedResign != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('퇴사일', formattedResign),
                    ],
                    const SizedBox(height: 8),
                    _buildInfoRow('연락처', contact.isEmpty ? '-' : contact),
                  ],
                ),
              ),
            ],
          ),
          if (showEditButton) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onEditTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: AppColors.grey0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(isEditMode ? '취소' : '수정'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return SizedBox(
      width: 64,
      height: 64,
      child: profileImageUrl != null && profileImageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.network(
                profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
              ),
            )
          : _buildPlaceholderIcon(),
    );
  }

  Widget _buildPlaceholderIcon() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: SvgPicture.asset(
        'assets/icons/svg/icon/profile_default_80.svg',
        width: 64,
        height: 64,
        fit: BoxFit.cover,
      ),
    );
  }

  /// 라벨 스타일: #666874, 14px, weight 500, line-height 16px
  static const TextStyle _labelStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 16 / 14,
    color: Color(0xFF666874),
  );

  /// 값 스타일: #000, 14px, weight 400, line-height 19px
  static const TextStyle _valueStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 19 / 14,
    color: Color(0xFF000000),
  );

  Widget _buildNameValue() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (starCount != null && starCount! > 0)
          ...List.generate(
            starCount!.clamp(0, 3),
            (_) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: SizedBox(
                width: 16,
                height: 16,
                child: Image.asset(
                  'assets/icons/png/common/star_icon.png',
                  width: 16,
                  height: 16,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        if (starCount != null && starCount! > 0) const SizedBox(width: 6),
        Text(name.isEmpty ? '-' : name, style: _valueStyle),
      ],
    );
  }

  /// 등록 화면처럼 양 끝 배치 (Space Between)
  Widget _buildInfoRow(String label, dynamic value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: _labelStyle),
        if (value is Widget)
          value
        else
          Flexible(
            child: Text(
              value.toString(),
              style: _valueStyle,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
      ],
    );
  }
}
