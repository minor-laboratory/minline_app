import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'subscription_service.dart';

part 'subscription_service_provider.g.dart';

/// SubscriptionService Provider (keepAlive: true)
///
/// 앱 전체 생명주기 동안 유지되는 singleton 서비스
@Riverpod(keepAlive: true)
SubscriptionService subscriptionService(Ref ref) {
  final service = SubscriptionService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

/// 프리미엄 상태 Provider
///
/// 실시간으로 프리미엄 상태를 확인
@riverpod
Future<bool> isPremium(Ref ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  return await service.isPremium();
}

/// 사용 가능한 패키지 목록 Provider
@riverpod
Future<List<Package>> availablePackages(Ref ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  return await service.getAvailablePackages();
}

/// 고객 정보 Provider
@riverpod
Future<CustomerInfo> customerInfo(Ref ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  return await service.getCustomerInfo();
}
