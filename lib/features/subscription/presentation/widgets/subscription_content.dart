import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/services/subscription_service.dart';
import '../../../../core/services/subscription_service_provider.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/utils/logger.dart';

/// 구독 UI 핵심 컨텐츠 위젯
///
/// SubscriptionPage와 SubscriptionSheet에서 재사용
class SubscriptionContent extends ConsumerStatefulWidget {
  /// 콤팩트 모드 (BottomSheet에서 사용 시)
  final bool compact;

  /// 구독 완료 시 콜백
  final VoidCallback? onSubscribed;

  const SubscriptionContent({
    super.key,
    this.compact = false,
    this.onSubscribed,
  });

  @override
  ConsumerState<SubscriptionContent> createState() => _SubscriptionContentState();
}

class _SubscriptionContentState extends ConsumerState<SubscriptionContent> {
  bool _isLoading = false;
  bool _isRestoring = false;
  String? _selectedPackageId;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final packagesAsync = ref.watch(availablePackagesProvider);
    final isPremiumAsync = ref.watch(isPremiumProvider);

    return isPremiumAsync.when(
      data: (isPremium) {
        if (isPremium) {
          return _buildPremiumStatus(context, theme);
        }
        return packagesAsync.when(
          data: (packages) => _buildSubscriptionOptions(context, theme, packages),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildError(context, theme, e),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildError(context, theme, e),
    );
  }

  /// 프리미엄 상태 표시
  Widget _buildPremiumStatus(BuildContext context, ShadThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(common.Spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(common.Spacing.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(common.Spacing.md),
            ),
            child: Icon(
              AppIcons.crown,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: common.Spacing.md),
          Text(
            'subscription.premium_user'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: common.Spacing.sm),
          Text(
            'premium.subtitle'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 구독 옵션 표시
  Widget _buildSubscriptionOptions(
    BuildContext context,
    ShadThemeData theme,
    List<Package> packages,
  ) {
    // 월간/연간 패키지 찾기
    final monthlyPackage = packages.firstWhereOrNull(
      (p) => p.packageType == PackageType.monthly,
    );
    final yearlyPackage = packages.firstWhereOrNull(
      (p) => p.packageType == PackageType.annual,
    );

    // 기본 선택 (연간 우선)
    _selectedPackageId ??= yearlyPackage?.identifier ?? monthlyPackage?.identifier;

    return SingleChildScrollView(
      padding: EdgeInsets.all(widget.compact ? common.Spacing.md : common.Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더 (콤팩트가 아닐 때만)
          if (!widget.compact) ...[
            Text(
              'premium.title'.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: common.Spacing.sm),
            Text(
              'premium.subtitle'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: common.Spacing.lg),
          ],

          // 프리미엄 기능 목록
          _buildFeatureList(context, theme),
          SizedBox(height: common.Spacing.lg),

          // 구독 옵션 카드
          if (yearlyPackage != null)
            _buildPackageCard(
              context,
              theme,
              yearlyPackage,
              isSelected: _selectedPackageId == yearlyPackage.identifier,
              isBestValue: true,
            ),
          if (yearlyPackage != null && monthlyPackage != null)
            SizedBox(height: common.Spacing.sm),
          if (monthlyPackage != null)
            _buildPackageCard(
              context,
              theme,
              monthlyPackage,
              isSelected: _selectedPackageId == monthlyPackage.identifier,
            ),

          SizedBox(height: common.Spacing.lg),

          // 구독 버튼
          ShadButton(
            onPressed: _isLoading ? null : _handleSubscribe,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('subscription.subscribe'.tr()),
          ),

          SizedBox(height: common.Spacing.sm),

          // 복원 버튼
          ShadButton.ghost(
            onPressed: _isRestoring ? null : _handleRestore,
            child: _isRestoring
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('subscription.restore'.tr()),
          ),

          SizedBox(height: common.Spacing.md),

          // 안내 문구
          Text(
            'subscription.terms_notice'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: common.Spacing.xs),
          Text(
            'subscription.cancel_anytime'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 기능 목록
  Widget _buildFeatureList(BuildContext context, ShadThemeData theme) {
    final features = [
      ('premium.feature_unlimited'.tr(), AppIcons.infinity),
      ('premium.feature_realtime'.tr(), AppIcons.zap),
      ('premium.feature_storage'.tr(), AppIcons.database),
      ('premium.feature_priority'.tr(), AppIcons.star),
    ];

    return Container(
      padding: const EdgeInsets.all(common.Spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(common.Spacing.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'subscription.features_title'.tr(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: common.Spacing.sm),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.symmetric(vertical: common.Spacing.xs),
            child: Row(
              children: [
                Icon(f.$2, size: 16, color: theme.colorScheme.primary),
                SizedBox(width: common.Spacing.sm),
                Text(f.$1, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// 패키지 카드
  Widget _buildPackageCard(
    BuildContext context,
    ShadThemeData theme,
    Package package, {
    required bool isSelected,
    bool isBestValue = false,
  }) {
    final isMonthly = package.packageType == PackageType.monthly;
    final priceString = package.storeProduct.priceString;

    return GestureDetector(
      onTap: () => setState(() => _selectedPackageId = package.identifier),
      child: Container(
        padding: const EdgeInsets.all(common.Spacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.card,
          borderRadius: BorderRadius.circular(common.Spacing.sm),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 라디오 버튼
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: common.Spacing.md),
            // 패키지 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isMonthly
                            ? 'subscription.monthly'.tr()
                            : 'subscription.yearly'.tr(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isBestValue) ...[
                        SizedBox(width: common.Spacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: common.Spacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(common.Spacing.xs),
                          ),
                          child: Text(
                            'subscription.best_value'.tr(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primaryForeground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    isMonthly
                        ? 'subscription.monthly_price'.tr(namedArgs: {'price': priceString})
                        : 'subscription.yearly_price'.tr(namedArgs: {'price': priceString}),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 에러 표시
  Widget _buildError(BuildContext context, ShadThemeData theme, Object error) {
    return Padding(
      padding: const EdgeInsets.all(common.Spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppIcons.error,
            size: 48,
            color: theme.colorScheme.destructive,
          ),
          SizedBox(height: common.Spacing.md),
          Text(
            'common.error'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: common.Spacing.md),
          ShadButton.outline(
            onPressed: () {
              ref.invalidate(availablePackagesProvider);
              ref.invalidate(isPremiumProvider);
            },
            child: Text('common.retry'.tr()),
          ),
        ],
      ),
    );
  }

  /// 구독 처리
  Future<void> _handleSubscribe() async {
    if (_selectedPackageId == null) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(subscriptionServiceProvider);
      final packages = await service.getAvailablePackages();
      final package = packages.firstWhereOrNull(
        (p) => p.identifier == _selectedPackageId,
      );

      if (package == null) {
        throw Exception('Package not found');
      }

      final result = await service.purchasePackage(package);

      if (result != null && mounted) {
        // 구독 성공
        ref.invalidate(isPremiumProvider);
        widget.onSubscribed?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('subscription.subscribed'.tr())),
        );
      }
    } catch (e, stack) {
      logger.e('Purchase failed', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('subscription.purchase_failed'.tr())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 복원 처리
  Future<void> _handleRestore() async {
    setState(() => _isRestoring = true);

    try {
      final service = ref.read(subscriptionServiceProvider);
      final customerInfo = await service.restorePurchases();

      final isPremium = customerInfo
          .entitlements.all[SubscriptionService.premiumEntitlementId]?.isActive ?? false;

      if (mounted) {
        ref.invalidate(isPremiumProvider);

        if (isPremium) {
          widget.onSubscribed?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('subscription.restore_success'.tr())),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('subscription.restore_not_found'.tr())),
          );
        }
      }
    } catch (e, stack) {
      logger.e('Restore failed', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('subscription.restore_failed'.tr())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }
}
