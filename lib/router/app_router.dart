import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;

import '../core/services/local_notification_service.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/feedback/presentation/pages/feedback_page.dart';
import '../features/main/presentation/pages/main_page.dart';
import '../features/posts/presentation/pages/post_create_page.dart';
import '../features/posts/presentation/pages/post_detail_page.dart';
import '../features/profile/presentation/pages/account_withdrawal_page.dart';
import '../features/profile/presentation/pages/password_change_page.dart';
import '../features/profile/presentation/pages/profile_detail_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/share/presentation/pages/share_input_page.dart';
import '../features/timeline/presentation/pages/tag_edit_page.dart';

/// Navigator Key for ShareHandlerService
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 국가 코드 가져오기 (언어 설정 기반)
String _getCountryCode(BuildContext context) {
  final locale = context.locale;
  // 한국어 → KR, 영어 → US
  if (locale.languageCode == 'ko') return 'KR';
  return 'US';
}

/// 앱 라우터 설정
final appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/',
  routes: [
    // Main (메인 화면 - Timeline/Drafts/Posts)
    GoRoute(
      path: '/',
      name: 'main',
      builder: (context, state) {
        final tabParam = state.uri.queryParameters['tab'];
        final initialTab = int.tryParse(tabParam ?? '0') ?? 0;
        return MainPage(initialTab: initialTab);
      },
      routes: [
        // 태그 추가
        GoRoute(
          path: 'tag/edit/:fragmentId',
          builder: (context, state) {
            final fragmentId = state.pathParameters['fragmentId']!;
            return TagEditPage(fragmentId: fragmentId);
          },
        ),
      ],
    ),

    // Auth
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (context, state) => const AuthPage(),
      routes: [
        // 비밀번호 재설정
        GoRoute(
          path: 'reset-password',
          builder: (context, state) => const common.PasswordResetPage(),
        ),
      ],
    ),

    // Post 관련 라우트 (MainPage 밖에서 독립)
    GoRoute(
      path: '/posts/create/:draftId',
      builder: (context, state) {
        final draftId = state.pathParameters['draftId']!;
        final previousVersionId = state.uri.queryParameters['previousVersionId'];
        return PostCreatePage(
          draftId: draftId,
          previousVersionId: previousVersionId,
        );
      },
    ),
    GoRoute(
      path: '/posts/:postId',
      builder: (context, state) {
        final postId = state.pathParameters['postId']!;
        return PostDetailPage(postId: postId);
      },
    ),

    // Profile
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileDetailPage(),
    ),

    // Settings
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
      routes: [
        // 프로필 비밀번호 변경
        GoRoute(
          path: 'profile/password',
          builder: (context, state) => const PasswordChangePage(),
        ),
        // 회원 탈퇴
        GoRoute(
          path: 'account/withdrawal',
          builder: (context, state) => const AccountWithdrawalPage(),
        ),
        // 이용약관
        GoRoute(
          path: 'terms',
          builder: (context, state) => common.PolicyLatestPage(
            policyType: 'terms',
            country: _getCountryCode(context),
          ),
        ),
        // 개인정보처리방침
        GoRoute(
          path: 'privacy',
          builder: (context, state) => common.PolicyLatestPage(
            policyType: 'privacy',
            country: _getCountryCode(context),
          ),
        ),
      ],
    ),

    // Feedback
    GoRoute(
      path: '/feedback/:targetType/:targetId',
      name: 'feedback',
      builder: (context, state) {
        final targetType = state.pathParameters['targetType']!;
        final targetId = state.pathParameters['targetId']!;
        return FeedbackPage(
          targetType: targetType,
          targetId: targetId,
        );
      },
    ),

    // Share Input (공유 받은 데이터 입력)
    GoRoute(
      path: '/share/input',
      name: 'share_input',
      builder: (context, state) => const ShareInputPage(),
    ),

    // Test Notification (ADB 테스트용)
    GoRoute(
      path: '/test-notification',
      name: 'test_notification',
      redirect: (context, state) {
        // 테스트 notification 표시
        LocalNotificationService().showTestNotification();
        // 메인 화면으로 리다이렉트
        return '/';
      },
    ),
  ],
);
