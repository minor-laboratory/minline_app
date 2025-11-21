import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';

import '../../env/app_env.dart';
import '../utils/logger.dart';

/// RevenueCat 구독 서비스
///
/// 구독 상태 관리, 구매, 복원 등을 담당
class SubscriptionService {
  bool _isInitialized = false;

  /// 구독 상품 ID (RevenueCat에서 설정)
  static const String monthlyProductId = 'miniline_premium_monthly';
  static const String yearlyProductId = 'miniline_premium_yearly';

  /// Entitlement ID (RevenueCat에서 설정)
  static const String premiumEntitlementId = 'premium';

  /// RevenueCat 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final apiKey = Platform.isIOS
          ? AppEnv.revenueCatApiKeyIos
          : AppEnv.revenueCatApiKeyAndroid;

      await Purchases.configure(PurchasesConfiguration(apiKey));
      _isInitialized = true;
      logger.i('RevenueCat initialized');
    } catch (e, stack) {
      logger.e('RevenueCat initialization failed', e, stack);
      rethrow;
    }
  }

  /// 현재 사용자가 프리미엄인지 확인
  Future<bool> isPremium() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[premiumEntitlementId]?.isActive ??
          false;
    } catch (e, stack) {
      logger.e('Failed to check premium status', e, stack);
      return false;
    }
  }

  /// 고객 정보 조회
  Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  /// 사용 가능한 패키지 목록 조회
  Future<List<Package>> getAvailablePackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      final currentOffering = offerings.current;

      if (currentOffering == null) {
        logger.w('No current offering available');
        return [];
      }

      return currentOffering.availablePackages;
    } catch (e, stack) {
      logger.e('Failed to get offerings', e, stack);
      return [];
    }
  }

  /// 패키지 구매
  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      // ignore: deprecated_member_use
      final result = await Purchases.purchasePackage(package);
      logger.i('Purchase successful: ${package.identifier}');
      return result.customerInfo;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        logger.i('Purchase cancelled by user');
        return null;
      }
      logger.e('Purchase failed', e);
      rethrow;
    } catch (e, stack) {
      logger.e('Purchase failed', e, stack);
      rethrow;
    }
  }

  /// 구매 복원
  Future<CustomerInfo> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      logger.i('Purchases restored');
      return customerInfo;
    } catch (e, stack) {
      logger.e('Failed to restore purchases', e, stack);
      rethrow;
    }
  }

  /// 사용자 ID 설정 (로그인 시)
  Future<void> setUserId(String userId) async {
    try {
      await Purchases.logIn(userId);
      logger.i('RevenueCat user logged in: $userId');
    } catch (e, stack) {
      logger.e('Failed to set RevenueCat user ID', e, stack);
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    try {
      await Purchases.logOut();
      logger.i('RevenueCat user logged out');
    } catch (e, stack) {
      logger.e('Failed to logout from RevenueCat', e, stack);
    }
  }

  void dispose() {
    // RevenueCat SDK는 별도 dispose 불필요
  }
}
