import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../account_dio_message.dart';
import '../widgets/account_confirm_dialogs.dart';
import '../widgets/account_figma_styles.dart';
import 'account_profile_screen.dart';

/// 내 정보 설정 (Figma 2634:16115)
class AccountMyInfoSettingsScreen extends StatefulWidget {
  const AccountMyInfoSettingsScreen({super.key});

  @override
  State<AccountMyInfoSettingsScreen> createState() =>
      _AccountMyInfoSettingsScreenState();
}

class _AccountMyInfoSettingsScreenState
    extends State<AccountMyInfoSettingsScreen> {
  bool _busy = false;

  Future<void> _onWithdraw() async {
    if (!mounted) return;
    final ok = await showWithdrawConfirmDialog(context);
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthRepository>().withdrawAccount();
      if (!mounted) return;
      context.read<AuthBloc>().add(const AuthLogoutRequested());
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accountDioMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey0Alt,
      appBar: accountFigmaAppBar(context: context, title: '내 정보 설정'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.grey0,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _row(
                  context,
                  '내 정보 변경',
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const AccountProfileScreen(),
                      ),
                    );
                  },
                ),
                _row(
                  context,
                  '탈퇴하기',
                  onTap: () {
                    if (_busy) return;
                    _onWithdraw();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String title, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(title, style: AccountFigmaStyles.rowTitle),
              ),
              AccountFigmaStyles.chevronNext16(),
            ],
          ),
        ),
      ),
    );
  }
}
