import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/utils/app_icons.dart';
import '../../../core/utils/storage_utils.dart';
import '../../../features/drafts/providers/drafts_provider.dart';
import '../../../features/posts/providers/posts_provider.dart';
import '../../../features/timeline/providers/fragments_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// 사용자 프로필 카드 위젯 (설정 페이지 상단)
class UserProfileSection extends ConsumerWidget {
  const UserProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final isLoggedIn = currentUser != null;

    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: common.Spacing.lg),
      child: ShadCard(
        padding: const EdgeInsets.all(common.Spacing.lg),
        child: Column(
          children: [
            // 프로필 이미지 (클릭 가능)
            InkWell(
              onTap: isLoggedIn
                  ? () => context.push('/profile')
                  : () => context.push('/auth'),
              borderRadius: BorderRadius.circular(48),
              child: userProfileAsync.when(
                data: (profile) => _buildProfileAvatar(
                  context,
                  colorScheme,
                  profile,
                  currentUser,
                ),
                loading: () => SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
                error: (_, __) => _buildProfileAvatar(
                  context,
                  colorScheme,
                  null,
                  currentUser,
                ),
              ),
            ),

            const SizedBox(height: common.Spacing.md),

            // 이름 표시
            userProfileAsync.when(
              data: (profile) {
                final userName = isLoggedIn
                    ? (profile?['name'] ??
                        currentUser.email.split('@')[0] ??
                        'common.user'.tr())
                    : 'auth.guest'.tr();

                return Text(
                  userName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                );
              },
              loading: () => Container(
                height: 20,
                width: 100,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              error: (_, __) => Text(
                isLoggedIn ? 'common.user'.tr() : 'auth.guest'.tr(),
                style: theme.textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: common.Spacing.lg),

            // 게스트 vs 로그인 사용자
            if (!isLoggedIn)
              // 게스트: 로그인 유도
              SizedBox(
                width: double.infinity,
                child: ShadButton(
                  onPressed: () => context.push('/auth'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(AppIcons.login, size: 16),
                      const SizedBox(width: common.Spacing.xs),
                      Text('auth.login'.tr()),
                    ],
                  ),
                ),
              )
            else
              // 로그인 사용자: 1x3 통계 (가로 배치)
              _buildStatistics(context, ref, theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(
    BuildContext context,
    WidgetRef ref,
    ShadThemeData theme,
    ShadColorScheme colorScheme,
  ) {
    final fragmentCountAsync = ref.watch(fragmentCountProvider);
    final draftCountsAsync = ref.watch(draftCountsProvider);
    final postCountAsync = ref.watch(postsCountProvider);

    return Row(
      children: [
        // Fragment
        Expanded(
          child: GestureDetector(
            onTap: () => context.go('/timeline'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: common.Spacing.md,
                horizontal: common.Spacing.sm,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.sparkles,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: common.Spacing.xs),
                  fragmentCountAsync.when(
                    data: (count) => Text(
                      count.toString(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, __) => Text('0', style: theme.textTheme.headlineMedium),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'timeline.fragments'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: common.Spacing.sm),

        // Draft
        Expanded(
          child: GestureDetector(
            onTap: () => context.go('/drafts'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: common.Spacing.md,
                horizontal: common.Spacing.sm,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.drafts,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: common.Spacing.xs),
                  draftCountsAsync.when(
                    data: (counts) => Text(
                      counts['all'].toString(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, __) => Text('0', style: theme.textTheme.headlineMedium),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'drafts.title'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: common.Spacing.sm),

        // Post
        Expanded(
          child: GestureDetector(
            onTap: () => context.go('/posts'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: common.Spacing.md,
                horizontal: common.Spacing.sm,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.posts,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: common.Spacing.xs),
                  postCountAsync.when(
                    data: (count) => Text(
                      count.toString(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, __) => Text('0', style: theme.textTheme.headlineMedium),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'posts.title'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar(
    BuildContext context,
    ShadColorScheme colorScheme,
    Map<String, dynamic>? profile,
    dynamic currentUser,
  ) {
    String? imageUrl;
    if (profile?['photo_url'] != null && currentUser != null) {
      final photoUrl = profile!['photo_url'] as String;
      final userId = currentUser.id;
      imageUrl = StorageUtils.getUserPhotoUrl(userId, photoUrl);
    }

    // 기본 아바타 위젯
    Widget defaultAvatar = Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Icon(
        AppIcons.user,
        size: 48,
        color: colorScheme.onPrimaryContainer,
      ),
    );

    // 이미지가 있는 경우
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 96,
          height: 96,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => defaultAvatar,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return defaultAvatar;
            },
          ),
        ),
      );
    }

    return defaultAvatar;
  }
}
