import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/services/local_change_tracker.dart';
import '../../../core/utils/app_icons.dart';
import '../../../shared/widgets/responsive_modal_sheet.dart';

/// 로그아웃 확인 Bottom Sheet (미동기화 항목 표시)
class LogoutConfirmationSheet extends ConsumerStatefulWidget {
  const LogoutConfirmationSheet({super.key});

  @override
  ConsumerState<LogoutConfirmationSheet> createState() =>
      _LogoutConfirmationSheetState();
}

class _LogoutConfirmationSheetState
    extends ConsumerState<LogoutConfirmationSheet> {
  bool _isChecking = true;
  int _unsyncedFragments = 0;
  int _unsyncedDrafts = 0;
  int _unsyncedPosts = 0;

  @override
  void initState() {
    super.initState();
    _checkUnsyncedItems();
  }

  Future<void> _checkUnsyncedItems() async {
    try {
      final changeTracker = LocalChangeTracker();
      final unsyncedCounts = await changeTracker.getUnsyncedItemsCounts();

      _unsyncedFragments = unsyncedCounts['fragments'] ?? 0;
      _unsyncedDrafts = unsyncedCounts['drafts'] ?? 0;
      _unsyncedPosts = unsyncedCounts['posts'] ?? 0;
    } catch (e) {
      // 에러 발생 시 0으로 처리
      _unsyncedFragments = 0;
      _unsyncedDrafts = 0;
      _unsyncedPosts = 0;
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final materialTheme = Theme.of(context);
    final totalUnsynced = _unsyncedFragments + _unsyncedDrafts + _unsyncedPosts;

    return Padding(
      padding: const EdgeInsets.all(common.Spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 설명 메시지
          Text(
            _isChecking
                ? 'sync.checking'.tr()
                : totalUnsynced > 0
                    ? 'auth.logout_unsynced_warning'.tr()
                    : 'auth.logout_confirm'.tr(),
            style: materialTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: common.Spacing.lg),

          // Content
          if (_isChecking)
            const Center(
              child: CircularProgressIndicator(),
            )
          else ...[
            if (totalUnsynced > 0) ...[
              // 경고 메시지
              Container(
                padding: const EdgeInsets.all(common.Spacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(common.BorderRadii.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.warning,
                      color: theme.colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: common.Spacing.sm),
                    Expanded(
                      child: Text(
                        'sync.unsynced_items_exist'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: common.Spacing.lg),

              // 미동기화 항목 목록
              if (_unsyncedFragments > 0)
                _buildUnsyncedItem(
                  theme,
                  icon: AppIcons.sparkles,
                  label: 'timeline.fragments'.tr(),
                  count: _unsyncedFragments,
                ),
              if (_unsyncedDrafts > 0)
                _buildUnsyncedItem(
                  theme,
                  icon: AppIcons.drafts,
                  label: 'drafts.title'.tr(),
                  count: _unsyncedDrafts,
                ),
              if (_unsyncedPosts > 0)
                _buildUnsyncedItem(
                  theme,
                  icon: AppIcons.posts,
                  label: 'posts.title'.tr(),
                  count: _unsyncedPosts,
                ),
              const SizedBox(height: common.Spacing.lg),

              // 데이터 손실 경고
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
                        'auth.logout_data_loss_warning'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 모든 데이터 동기화됨
              Container(
                padding: const EdgeInsets.all(common.Spacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(common.BorderRadii.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.checkCircle,
                      color: theme.colorScheme.onSecondaryContainer,
                      size: 20,
                    ),
                    const SizedBox(width: common.Spacing.sm),
                    Text(
                      'sync.all_data_synced'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: common.Spacing.xxl),

          // 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ShadButton.outline(
                onPressed: () => Navigator.pop(context, false),
                foregroundColor: theme.colorScheme.foreground,
                child: Text('common.cancel'.tr()),
              ),
              const SizedBox(width: common.Spacing.md),
              if (!_isChecking)
                ShadButton(
                  onPressed: () => Navigator.pop(context, true),
                  backgroundColor: totalUnsynced > 0
                      ? materialTheme.colorScheme.error
                      : null,
                  foregroundColor: totalUnsynced > 0
                      ? materialTheme.colorScheme.onError
                      : null,
                  child: Text(
                    totalUnsynced > 0
                        ? 'auth.logout_anyway'.tr()
                        : 'auth.logout'.tr(),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnsyncedItem(
    ShadThemeData theme, {
    required IconData icon,
    required String label,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: common.Spacing.xs),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: common.Spacing.xs),
          Text('$label:', style: theme.textTheme.bodyMedium),
          const SizedBox(width: common.Spacing.xs),
          Text(
            '$count',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

/// 로그아웃 확인 Bottom Sheet 표시 헬퍼 함수
Future<bool?> showLogoutConfirmationBottomSheet(BuildContext context) {
  final theme = ShadTheme.of(context);
  final materialTheme = Theme.of(context);
  final cardColor = theme.colorScheme.card;

  return ResponsiveModalSheet.show<bool>(
    context: context,
    barrierDismissible: true,
    enableDrag: true,
    pages: [
      ResponsiveModalSheet.createPage(
        topBarTitle: 'auth.logout'.tr(),
        topBarTitleStyle: materialTheme.textTheme.titleLarge,
        hasTopBarLayer: true,
        backgroundColor: cardColor,
        child: const LogoutConfirmationSheet(),
      ),
    ],
  );
}
