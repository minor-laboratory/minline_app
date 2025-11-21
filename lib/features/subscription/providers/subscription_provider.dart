import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/logger.dart';

part 'subscription_provider.g.dart';

/// 구독 정보 모델
class SubscriptionInfo {
  final bool isPremium;
  final int freePostsCount;
  final DateTime freePostsResetAt;

  const SubscriptionInfo({
    required this.isPremium,
    required this.freePostsCount,
    required this.freePostsResetAt,
  });

  /// 무료 한도 초과 여부
  bool get isFreeLimitExceeded => !isPremium && freePostsCount >= 3;

  /// 다음 리셋까지 남은 일수
  int get daysUntilReset {
    return freePostsResetAt.difference(DateTime.now()).inDays;
  }
}

/// 구독 정보 Provider
@riverpod
Future<SubscriptionInfo> subscription(Ref ref) async {
  try {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      logger.w('[Subscription] User not authenticated');
      // 기본값 반환 (무료 사용자, 0개 사용)
      return SubscriptionInfo(
        isPremium: false,
        freePostsCount: 0,
        freePostsResetAt: DateTime(
          DateTime.now().year,
          DateTime.now().month + 1,
          1,
        ),
      );
    }

    final response = await supabase
        .from('user_subscriptions')
        .select('is_premium, free_posts_count, free_posts_reset_at')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      logger.i('[Subscription] No subscription data, returning defaults');
      // 구독 정보 없으면 기본값 (무료 사용자, 0개 사용)
      return SubscriptionInfo(
        isPremium: false,
        freePostsCount: 0,
        freePostsResetAt: DateTime(
          DateTime.now().year,
          DateTime.now().month + 1,
          1,
        ),
      );
    }

    return SubscriptionInfo(
      isPremium: response['is_premium'] as bool? ?? false,
      freePostsCount: response['free_posts_count'] as int? ?? 0,
      freePostsResetAt: DateTime.parse(
        response['free_posts_reset_at'] as String,
      ),
    );
  } catch (e, stack) {
    logger.e('[Subscription] Failed to load subscription info', e, stack);
    // 에러 시 기본값 반환
    return SubscriptionInfo(
      isPremium: false,
      freePostsCount: 0,
      freePostsResetAt: DateTime(
        DateTime.now().year,
        DateTime.now().month + 1,
        1,
      ),
    );
  }
}
