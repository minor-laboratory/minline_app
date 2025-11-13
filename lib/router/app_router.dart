import 'package:go_router/go_router.dart';

import '../features/drafts/presentation/pages/drafts_page.dart';
import '../features/posts/presentation/pages/posts_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/timeline/presentation/pages/timeline_page.dart';

/// 앱 라우터 설정
final appRouter = GoRouter(
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
    ),

    // Settings
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
