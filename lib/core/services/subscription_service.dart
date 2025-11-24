import 'dart:math' show min;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../env/app_env.dart';
import '../utils/logger.dart';

/// RevenueCat 구독 관리 서비스
///
/// 구독 유형:
/// - 월 구독: MiniLine 프리미엄
/// - 연 구독: MiniLine 프리미엄 (할인)
/// - 평생 라이선스: 1회 결제
class SubscriptionService {
  // 제품 ID (RevenueCat Package Identifier)
  static const String monthlyPackageId = '\$rc_monthly';
  static const String annualPackageId = '\$rc_annual';
  static const String lifetimePackageId = '\$rc_lifetime';

  /// Entitlement ID (RevenueCat에서 설정)
  static const String premiumEntitlementId = 'Pro';

  SubscriptionService();

  bool _isInitialized = false;
  CustomerInfo? _customerInfo;

  /// RevenueCat 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 디버그 모드에서 상세 로깅 활성화
      await Purchases.setLogLevel(LogLevel.debug);

      // 플랫폼별 API 키 설정
      final isAndroid = defaultTargetPlatform == TargetPlatform.android;
      final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
      logger.i(
        'Initializing RevenueCat for ${isAndroid ? "Android" : isIOS ? "iOS" : "Unknown"}',
      );

      final apiKey = isAndroid
          ? AppEnv.revenueCatApiKeyAndroid
          : AppEnv.revenueCatApiKeyIos;

      if (apiKey.isEmpty) {
        final errorMsg =
            'RevenueCat API key not configured for ${isAndroid ? "Android" : "iOS"}';
        logger.e(errorMsg);
        throw Exception(errorMsg);
      }

      logger.i('Using API Key: ${apiKey.substring(0, min(10, apiKey.length))}...');

      // RevenueCat 설정
      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);
      logger.i('RevenueCat configured successfully');

      // 고객 정보 리스너 설정
      Purchases.addCustomerInfoUpdateListener((info) {
        _customerInfo = info;
        logger.i('Customer info updated: entitlements=${info.entitlements.active.length}');
      });

      // 초기 고객 정보 로드
      try {
        _customerInfo = await Purchases.getCustomerInfo();
        logger.i(
          'Initial customer info loaded: '
          'isSubscribed=${_customerInfo?.entitlements.active.isNotEmpty ?? false}, '
          'activeEntitlements=${_customerInfo?.entitlements.active.keys.join(", ") ?? "none"}',
        );
      } catch (e, stackTrace) {
        logger.e('Failed to load initial customer info (non-fatal)', e, stackTrace);
        _customerInfo = null;
      }

      _isInitialized = true;
      logger.i('RevenueCat initialized successfully');
    } catch (e, stackTrace) {
      logger.e('Failed to initialize RevenueCat', e, stackTrace);
      if (e.toString().contains('API key')) {
        throw Exception('subscription.error.invalid_api_key'.tr());
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        throw Exception('subscription.error.network'.tr());
      }
      rethrow;
    }
  }

  /// 사용자 식별 (로그인 시 호출)
  Future<void> login(String userId) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final result = await Purchases.logIn(userId);
      _customerInfo = result.customerInfo;
      logger.i('User logged in: $userId');
    } catch (e, stackTrace) {
      logger.e('Failed to login user', e, stackTrace);
      rethrow;
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    if (!_isInitialized) return;

    try {
      await Purchases.logOut();
      _customerInfo = null;
      logger.i('User logged out');
    } catch (e, stackTrace) {
      logger.e('Failed to logout', e, stackTrace);
    }
  }

  /// 현재 고객 정보 가져오기
  Future<CustomerInfo> getCustomerInfo() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _customerInfo = await Purchases.getCustomerInfo();
      return _customerInfo!;
    } catch (e, stackTrace) {
      logger.e('Failed to get customer info', e, stackTrace);
      rethrow;
    }
  }

  /// 구독 상태 확인
  Future<bool> isSubscribed() async {
    try {
      final customerInfo = await getCustomerInfo();

      // 활성 구독 확인
      final hasActiveSubscription = customerInfo.activeSubscriptions.isNotEmpty;

      // 평생 라이선스 확인 (Entitlement 기반)
      final hasPremiumEntitlement = customerInfo.entitlements.active.isNotEmpty;

      return hasActiveSubscription || hasPremiumEntitlement;
    } catch (e, stackTrace) {
      logger.e('Failed to check subscription status', e, stackTrace);
      return false;
    }
  }

  /// 프리미엄 기능 사용 가능 여부
  Future<bool> isPremium() async {
    try {
      final customerInfo = await getCustomerInfo();
      return customerInfo.entitlements.all[premiumEntitlementId]?.isActive ??
          false;
    } catch (e, stackTrace) {
      logger.e('Failed to check premium status', e, stackTrace);
      return false;
    }
  }

  /// 사용 가능한 패키지 목록 조회 (subscription_content.dart 호환용)
  Future<List<Package>> getAvailablePackages() async {
    try {
      final offerings = await getOfferings();
      final currentOffering = offerings.current;

      if (currentOffering == null) {
        logger.w('No current offering available');
        return [];
      }

      return currentOffering.availablePackages;
    } catch (e, stackTrace) {
      logger.e('Failed to get available packages', e, stackTrace);
      return [];
    }
  }

  /// 이용 가능한 제품 가져오기
  Future<Offerings> getOfferings() async {
    if (!_isInitialized) {
      logger.w('RevenueCat not initialized, initializing now...');
      await initialize();
    }

    try {
      logger.i('Fetching offerings from RevenueCat...');
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null) {
        logger.w('No current offering available');
      } else {
        logger.i('Current offering: ${offerings.current!.identifier}');
        logger.i('Available packages: ${offerings.current!.availablePackages.length}');
        for (final package in offerings.current!.availablePackages) {
          logger.i(
            'Package: ${package.identifier} - ${package.storeProduct.title} - ${package.storeProduct.priceString}',
          );
        }
      }

      return offerings;
    } catch (e, stackTrace) {
      logger.e('Failed to get offerings', e, stackTrace);
      logger.w('Returning empty offerings due to configuration error');
      return const Offerings({});
    }
  }

  /// 구독 구매
  Future<CustomerInfo> purchaseSubscription(Package package) async {
    logger.i('Starting purchase for package: ${package.identifier}');
    logger.i('Product: ${package.storeProduct.title}');
    logger.i('Price: ${package.storeProduct.priceString}');

    try {
      final purchaseResult =
          await Purchases.purchase(PurchaseParams.package(package));
      _customerInfo = purchaseResult.customerInfo;
      logger.i('Subscription purchased successfully');
      logger.i('Active subscriptions: ${_customerInfo!.activeSubscriptions}');
      return _customerInfo!;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);

      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        logger.i('Purchase cancelled by user');
      } else if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        logger.w('Product already purchased');
      } else if (errorCode ==
          PurchasesErrorCode.productNotAvailableForPurchaseError) {
        logger.e('Product not available for purchase');
      } else if (errorCode == PurchasesErrorCode.purchaseNotAllowedError) {
        logger.e('Purchase not allowed');
      } else if (errorCode == PurchasesErrorCode.configurationError) {
        logger.e('Configuration error - check RevenueCat setup');
      } else {
        logger.e('Purchase failed with error code: $errorCode', e);
      }
      rethrow;
    }
  }

  /// 구매 복원
  Future<CustomerInfo> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;
      logger.i('Purchases restored successfully');
      return customerInfo;
    } catch (e, stackTrace) {
      logger.e('Failed to restore purchases', e, stackTrace);
      rethrow;
    }
  }

  /// 구독 관리 페이지 열기
  Future<void> showManageSubscriptions() async {
    try {
      final customerInfo = await getCustomerInfo();

      // managementURL 확인
      final managementUrl = customerInfo.managementURL;

      if (managementUrl != null && managementUrl.isNotEmpty) {
        final uri = Uri.parse(managementUrl);
        logger.i('Opening subscription management URL: $managementUrl');

        final success =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (success) {
          logger.i('Successfully opened subscription management URL');
        } else {
          logger.e('Failed to open subscription management URL');
          throw Exception('subscription.error.cannot_open_management'.tr());
        }
      } else {
        logger.w('No management URL available - using platform fallback');

        // 플랫폼별 기본 구독 관리 페이지
        String fallbackUrl;
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          fallbackUrl = 'https://apps.apple.com/account/subscriptions';
          logger.i('Using fallback iOS subscription URL');
        } else if (defaultTargetPlatform == TargetPlatform.android) {
          fallbackUrl = 'https://play.google.com/store/account/subscriptions';
          logger.i('Using fallback Android subscription URL');
        } else {
          throw Exception('subscription.error.platform_not_supported'.tr());
        }

        final fallbackUri = Uri.parse(fallbackUrl);
        final success = await launchUrl(
          fallbackUri,
          mode: LaunchMode.externalApplication,
        );
        if (!success) {
          logger.e('Failed to open fallback subscription management URL');
          throw Exception('subscription.error.cannot_open_management'.tr());
        }
      }
    } catch (e, stackTrace) {
      logger.e('Failed to show manage subscriptions', e, stackTrace);
      rethrow;
    }
  }

  /// 현재 캐시된 고객 정보
  CustomerInfo? get customerInfo => _customerInfo;

  /// 초기화 상태
  bool get isInitialized => _isInitialized;

  /// purchasePackage (호환성을 위한 alias)
  Future<CustomerInfo?> purchasePackage(Package package) async {
    return await purchaseSubscription(package);
  }

  void dispose() {
    // RevenueCat SDK는 별도 dispose 불필요
  }
}
