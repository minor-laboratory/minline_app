import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;

import '../features/drafts/presentation/pages/drafts_page.dart';
import '../features/posts/presentation/pages/post_detail_page.dart';
import '../features/posts/presentation/pages/posts_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
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

    // Settings
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
      routes: [
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
  ],
);
