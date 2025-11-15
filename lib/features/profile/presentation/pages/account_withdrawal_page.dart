import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:minorlab_common/minorlab_common.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_icons.dart';
import '../../../../core/utils/logger.dart' as app_logger;
import '../../../auth/data/auth_repository.dart';

/// # AccountWithdrawal 화면 (회원 탈퇴)
///
/// ## 파일 정보
/// - 경로: `lib/features/profile/presentation/pages/account_withdrawal_page.dart`
/// - 라우트: `/settings/account/withdrawal`
/// - 진입점: ProfileDetailPage → 회원 탈퇴
///
class AccountWithdrawalPage extends ConsumerStatefulWidget {
  const AccountWithdrawalPage({super.key});

  @override
  ConsumerState<AccountWithdrawalPage> createState() =>
      _AccountWithdrawalPageState();
}

class _AccountWithdrawalPageState extends ConsumerState<AccountWithdrawalPage> {
  bool _confirmationChecked = false;
  bool _isLoading = false;
  final TextEditingController _confirmationController = TextEditingController();

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final canWithdraw =
        _confirmationChecked &&
        _confirmationController.text.trim().toLowerCase() ==
            'withdrawal_confirmation_text'.tr().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text('withdrawal_title'.tr(), style: textTheme.titleLarge),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 경고 아이콘과 제목
            Icon(AppIcons.warning, size: 64, color: colorScheme.destructive),
            const SizedBox(height: 16),

            Text(
              'withdrawal_warning_title'.tr(),
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.destructive,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // 탈퇴 안내사항
            Text('withdrawal_notice'.tr(), style: textTheme.bodyLarge),
            const SizedBox(height: 16),

            // 탈퇴 확인 체크박스
            CheckboxListTile(
              value: _confirmationChecked,
              onChanged: (value) {
                setState(() {
                  _confirmationChecked = value ?? false;
                });
              },
              title: Text(
                'withdrawal_agreement'.tr(),
                style: textTheme.bodyLarge,
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),

            // "탈퇴" 입력 필드
            ShadInput(
              controller: _confirmationController,
              placeholder: Text('withdrawal_confirmation_hint'.tr()),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // 버튼들
            Row(
              children: [
                Expanded(
                  child: ShadButton.ghost(
                    onPressed: _isLoading ? null : () => context.pop(),
                    child: Text(
                      'common.cancel'.tr(),
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.foreground,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ShadButton(
                    onPressed: (_isLoading || !canWithdraw)
                        ? null
                        : _processWithdrawal,
                    backgroundColor: colorScheme.destructive,
                    foregroundColor: colorScheme.destructiveForeground,
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.destructiveForeground,
                              ),
                            ),
                          )
                        : Text(
                            'withdrawal_button'.tr(),
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.destructiveForeground,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processWithdrawal() async {
    setState(() => _isLoading = true);

    try {
      // 탈퇴 처리
      await ref.read(authRepositoryProvider).requestWithdrawal();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('withdrawal_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );

        // 타임라인으로 이동
        context.go('/timeline');
      }
    } catch (e, stackTrace) {
      app_logger.logger.e('Withdrawal failed', e, stackTrace);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('withdrawal_error'.tr()),
            backgroundColor: ShadTheme.of(context).colorScheme.destructive,
          ),
        );
      }
    }
  }
}
