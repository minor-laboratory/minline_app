import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/utils/app_icons.dart';
import 'standard_bottom_sheet.dart';

/// 프리미엄 유도 시트
///
/// 무료 한도 초과 시 또는 프리미엄 기능 접근 시 표시
/// - 무료 vs 프리미엄 비교 테이블
/// - 프리미엄 기능 목록
/// - 업그레이드 버튼 (인앱결제 연결 - TODO)
class PremiumSheet extends StatelessWidget {
  const PremiumSheet({super.key});

  /// 프리미엄 시트 표시
  static Future<void> show(BuildContext context) async {
    await StandardBottomSheet.show(
      context: context,
      title: 'premium.title'.tr(),
      content: const PremiumSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 서브타이틀
          Padding(
            padding: const EdgeInsets.only(bottom: common.Spacing.md),
            child: Text(
              'premium.subtitle'.tr(),
              style: theme.textTheme.muted,
            ),
          ),

          // 비교 테이블
          _buildComparisonTable(context, theme),

          const SizedBox(height: common.Spacing.lg),

          // 프리미엄 기능 목록
          _buildFeatureList(context, theme),

          const SizedBox(height: common.Spacing.lg),

          // 업그레이드 버튼
          ShadButton(
            width: double.infinity,
            onPressed: () {
              // TODO: 인앱결제 연결
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('premium.coming_soon'.tr())),
              );
            },
            child: Text('premium.upgrade_button'.tr()),
          ),

          const SizedBox(height: common.Spacing.sm),

          // 구매 복원 버튼
          ShadButton.outline(
            width: double.infinity,
            onPressed: () {
              // TODO: 구매 복원
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('premium.coming_soon'.tr())),
              );
            },
            child: Text('premium.restore_purchase'.tr()),
          ),

          const SizedBox(height: common.Spacing.md),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context, ShadThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(common.BorderRadii.md),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(common.Spacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.muted,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(common.BorderRadii.md - 1),
              ),
            ),
            child: Row(
              children: [
                const Expanded(flex: 2, child: SizedBox()),
                Expanded(
                  flex: 2,
                  child: Text(
                    'premium.free_plan'.tr(),
                    style: theme.textTheme.small.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: common.Spacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'premium.premium_plan'.tr(),
                      style: theme.textTheme.small.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 글 생성
          _buildComparisonRow(
            context,
            theme,
            label: 'posts.title'.tr(),
            freeValue: 'premium.free_posts_limit'.tr(),
            premiumValue: 'premium.premium_posts_limit'.tr(),
          ),

          Divider(height: 1, color: theme.colorScheme.border),

          // AI 분석
          _buildComparisonRow(
            context,
            theme,
            label: 'drafts.title'.tr(),
            freeValue: 'premium.free_analysis'.tr(),
            premiumValue: 'premium.premium_analysis'.tr(),
          ),

          Divider(height: 1, color: theme.colorScheme.border),

          // 스토리지
          _buildComparisonRow(
            context,
            theme,
            label: 'Storage',
            freeValue: 'premium.free_storage'.tr(),
            premiumValue: 'premium.premium_storage'.tr(),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    BuildContext context,
    ShadThemeData theme, {
    required String label,
    required String freeValue,
    required String premiumValue,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(common.Spacing.sm),
      decoration: isLast
          ? const BoxDecoration(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(common.BorderRadii.md - 1),
              ),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.small,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              freeValue,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              premiumValue,
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context, ShadThemeData theme) {
    final features = [
      'premium.feature_unlimited',
      'premium.feature_realtime',
      'premium.feature_storage',
      'premium.feature_priority',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: common.Spacing.sm),
          child: Row(
            children: [
              Icon(
                AppIcons.checkCircle,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: common.Spacing.sm),
              Expanded(
                child: Text(
                  feature.tr(),
                  style: theme.textTheme.small,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
