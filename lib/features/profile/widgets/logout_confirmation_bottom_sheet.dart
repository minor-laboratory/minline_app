import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/utils/app_icons.dart';

/// 로그아웃 확인 Bottom Sheet
Future<bool?> showLogoutConfirmationBottomSheet(BuildContext context) {
  final theme = ShadTheme.of(context);

  return showShadSheet<bool>(
    context: context,
    builder: (context) => ShadSheet(
      title: Text('auth.logout'.tr()),
      description: Text('auth.logout_confirm'.tr()),
      child: Padding(
        padding: const EdgeInsets.all(common.Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 안내 메시지
            Container(
              padding: const EdgeInsets.all(common.Spacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(common.Spacing.sm),
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
                      'auth.logout_description'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: common.Spacing.xxl),

            // 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ShadButton.ghost(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('common.cancel'.tr()),
                ),
                const SizedBox(width: common.Spacing.md),
                ShadButton(
                  onPressed: () => Navigator.pop(context, true),
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  child: Text('auth.logout'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
