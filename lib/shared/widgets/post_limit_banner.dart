import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/utils/app_icons.dart';
import '../../features/subscription/providers/subscription_provider.dart';

/// 무료 한도 배너
///
/// 무료 사용자가 Post를 1개 이상 생성했을 때 표시
/// - 사용량 표시: "이번 달 N/3개 사용"
/// - 리셋 날짜 표시
/// - 한도 임박(2/3) 시 경고 색상
/// - 한도 초과(3/3) 시 destructive 색상
class PostLimitBanner extends ConsumerWidget {
  final VoidCallback? onUpgradeTap;

  const PostLimitBanner({
    super.key,
    this.onUpgradeTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionProvider);

    return subscriptionAsync.when(
      data: (subscription) {
        // 프리미엄 사용자는 표시 안함
        if (subscription.isPremium) {
          return const SizedBox.shrink();
        }

        // 사용량이 0이면 표시 안함
        if (subscription.freePostsCount == 0) {
          return const SizedBox.shrink();
        }

        final theme = ShadTheme.of(context);
        final isWarning = subscription.freePostsCount >= 2;
        final isExceeded = subscription.isFreeLimitExceeded;

        // 배경색 결정
        final backgroundColor = isExceeded
            ? theme.colorScheme.destructive.withValues(alpha: 0.1)
            : isWarning
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.muted;

        // 텍스트 색상 결정
        final textColor = isExceeded
            ? theme.colorScheme.destructive
            : isWarning
                ? theme.colorScheme.primary
                : theme.colorScheme.mutedForeground;

        // 리셋 날짜 포맷
        final resetDate =
            DateFormat('M/d').format(subscription.freePostsResetAt);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: common.Spacing.md,
            vertical: common.Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.border,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // 아이콘
              Icon(
                isExceeded ? AppIcons.warning : AppIcons.info,
                size: 16,
                color: textColor,
              ),
              const SizedBox(width: common.Spacing.sm),

              // 사용량 텍스트
              Expanded(
                child: Text(
                  'limit.free_posts_count'.tr(namedArgs: {
                    'current': subscription.freePostsCount.toString(),
                    'max': '3',
                  }),
                  style: theme.textTheme.small.copyWith(
                    color: textColor,
                  ),
                ),
              ),

              // 리셋 날짜
              Text(
                'limit.reset_at'.tr(namedArgs: {'date': resetDate}),
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                  fontSize: 11,
                ),
              ),

              // 한도 초과 시 업그레이드 버튼
              if (isExceeded && onUpgradeTap != null) ...[
                const SizedBox(width: common.Spacing.sm),
                GestureDetector(
                  onTap: onUpgradeTap,
                  child: Text(
                    'limit.upgrade_to_premium'.tr(),
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
