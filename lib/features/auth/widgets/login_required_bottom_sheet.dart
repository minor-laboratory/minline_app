import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/utils/app_icons.dart';
import '../../../shared/widgets/standard_bottom_sheet.dart';

/// 로그인 필요 안내 Bottom Sheet
///
/// 사용자가 로그인하지 않은 상태에서 저장 등의 작업을 시도할 때 표시
/// Bottom Sheet 형태로 로그인이 필요하다는 메시지와 함께 로그인 버튼 제공
Future<bool?> showLoginRequiredBottomSheet(BuildContext context) async {
  final theme = ShadTheme.of(context);

  // 먼저 sheet를 표시하고 결과를 받음
  final sheetResult = await StandardBottomSheet.show<bool>(
    context: context,
    title: 'auth.login_required'.tr(),
    titleStyle: BottomSheetTitleStyle.large,
    isDismissible: true,
    isDraggable: true,
    contentPadding: const EdgeInsets.all(common.Spacing.lg),
    content: _LoginRequiredContent(theme: theme),
    actions: [
      BottomSheetAction<bool>(
        text: 'common.cancel'.tr(),
        value: false,
        style: BottomSheetActionStyle.outlined,
      ),
      BottomSheetAction<bool>(
        text: 'auth.login'.tr(),
        value: true,
        style: BottomSheetActionStyle.elevated,
        icon: AppIcons.login,
      ),
    ],
    actionLayout: BottomSheetActionLayout.horizontal,
  );

  // 로그인 버튼을 눌렀을 때만 auth 페이지로 이동
  if (sheetResult == true && context.mounted) {
    context.push('/auth');
  }

  return sheetResult;
}

class _LoginRequiredContent extends StatelessWidget {
  final ShadThemeData theme;

  const _LoginRequiredContent({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 설명 메시지
        Text(
          'auth.login_required_to_save'.tr(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: common.Spacing.lg),

        // 설명 아이콘과 메시지
        Container(
          padding: const EdgeInsets.all(common.Spacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(common.BorderRadii.md),
          ),
          child: Row(
            children: [
              Icon(
                AppIcons.info,
                color: theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: common.Spacing.sm),
              Expanded(
                child: Text(
                  'auth.login_benefits'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: common.Spacing.xl),

        // 로그인 혜택 리스트
        _buildBenefitItem(
          theme,
          icon: AppIcons.sync,
          text: 'auth.benefit_sync'.tr(),
        ),
        const SizedBox(height: common.Spacing.sm),
        _buildBenefitItem(
          theme,
          icon: AppIcons.shield,
          text: 'auth.benefit_backup'.tr(),
        ),
        const SizedBox(height: common.Spacing.sm),
        _buildBenefitItem(
          theme,
          icon: AppIcons.sparkles,
          text: 'auth.benefit_ai'.tr(),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(ShadThemeData theme, {required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: common.Spacing.sm),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
