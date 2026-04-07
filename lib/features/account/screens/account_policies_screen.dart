import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../data/models/account_support_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../account_dio_message.dart';
import '../widgets/account_figma_styles.dart';
import 'account_policy_detail_screen.dart';

class AccountPoliciesScreen extends StatefulWidget {
  const AccountPoliciesScreen({super.key});

  @override
  State<AccountPoliciesScreen> createState() => _AccountPoliciesScreenState();
}

class _AccountPoliciesScreenState extends State<AccountPoliciesScreen> {
  List<AccountPolicySummary> _items = const [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<AuthRepository>().getPolicies();
      if (!mounted) return;
      setState(() {
        _items = data.items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _openPolicy(AccountPolicySummary item) async {
    if (!item.isConfigured) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('아직 문서가 등록되지 않았습니다.')));
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AccountPolicyDetailScreen(
          policyType: item.policyType,
          fallbackTitle: item.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: accountFigmaAppBar(context: context, title: '이용 정책'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _PoliciesErrorView(
                  message: accountDioMessage(_error!),
                  onRetry: _load,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => SizedBox(height: 14.h),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return InkWell(
                        onTap: () => _openPolicy(item),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.title} 보기',
                                  style: AppTypography.bodyMediumR.copyWith(
                                    color: item.isConfigured
                                        ? AppColors.textPrimary
                                        : AppColors.textDisabled,
                                    height: 20 / 14,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20.r,
                                color: item.isConfigured
                                    ? AppColors.textPrimary
                                    : AppColors.textDisabled,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _PoliciesErrorView extends StatelessWidget {
  const _PoliciesErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMediumR.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
