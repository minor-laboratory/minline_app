import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;

import '../features/auth/presentation/pages/auth_page.dart';
import '../features/drafts/presentation/pages/drafts_page.dart';
import '../features/feedback/presentation/pages/feedback_page.dart';
import '../features/posts/presentation/pages/post_create_page.dart';
import '../features/posts/presentation/pages/post_detail_page.dart';
import '../features/posts/presentation/pages/posts_page.dart';
import '../features/profile/presentation/pages/account_withdrawal_page.dart';
import '../features/profile/presentation/pages/password_change_page.dart';
import '../features/profile/presentation/pages/profile_detail_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/timeline/presentation/pages/tag_edit_page.dart';
import '../features/timeline/presentation/pages/timeline_page.dart';

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
    // Timeline (메인 화면)
    GoRoute(
      path: '/',
      name: 'timeline',
      builder: (context, state) => const TimelinePage(),
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

    // Drafts
    GoRoute(
      path: '/drafts',
      name: 'drafts',
      builder: (context, state) => const DraftsPage(),
    ),

    // Posts
    GoRoute(
      path: '/posts',
      name: 'posts',
      builder: (context, state) => const PostsPage(),
      routes: [
        // Post 생성
        GoRoute(
          path: 'create/:draftId',
          builder: (context, state) {
            final draftId = state.pathParameters['draftId']!;
            final previousVersionId = state.uri.queryParameters['previousVersionId'];
            return PostCreatePage(
              draftId: draftId,
              previousVersionId: previousVersionId,
            );
          },
        ),
        // Post 상세
        GoRoute(
          path: ':postId',
          builder: (context, state) {
            final postId = state.pathParameters['postId']!;
            return PostDetailPage(postId: postId);
          },
        ),
      ],
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
  ],
);
