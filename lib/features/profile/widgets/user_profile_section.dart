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

/// 프로필 디자인 Variant
enum ProfileDesignVariant {
  instagram, // 센터형, 2x2 그리드
  bear,      // 미니멀, 1x3 가로
  notion,    // 혼합형
}

/// 디자인 Variant ValueNotifier (디버그용)
final profileDesignVariantNotifier =
    ValueNotifier<ProfileDesignVariant>(ProfileDesignVariant.bear);

/// 사용자 프로필 카드 위젯 (설정 페이지 상단)
class UserProfileSection extends StatelessWidget {
  const UserProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProfileDesignVariant>(
      valueListenable: profileDesignVariantNotifier,
      builder: (context, variant, _) {
        switch (variant) {
          case ProfileDesignVariant.instagram:
            return const _InstagramStyleProfile();
          case ProfileDesignVariant.bear:
            return const _BearStyleProfile();
          case ProfileDesignVariant.notion:
            return const _NotionStyleProfile();
        }
      },
    );
  }
}

/// ========================================
/// Variant 1: Instagram 스타일
/// ========================================
class _InstagramStyleProfile extends ConsumerWidget {
  const _InstagramStyleProfile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final isLoggedIn = currentUser != null;

    final fragmentCountAsync = ref.watch(fragmentCountProvider);
    final draftCountsAsync = ref.watch(draftCountsProvider);
    final postCountAsync = ref.watch(postsCountProvider);

    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(common.Spacing.lg),
      child: ShadCard(
        padding: const EdgeInsets.all(common.Spacing.xl),
        child: Column(
          children: [
            // 프로필 이미지 (중앙)
            GestureDetector(
              onTap: isLoggedIn
                  ? () => context.push('/profile')
                  : () => context.push('/auth'),
              child: userProfileAsync.when(
                data: (profile) => _buildProfileAvatar(
                  context,
                  profile,
                  currentUser,
                  size: 96,
                ),
                loading: () => _buildSkeletonAvatar(context, size: 96),
                error: (_, __) => _buildDefaultAvatar(context, size: 96),
              ),
            ),

            const SizedBox(height: common.Spacing.md),

            // 이름 + 이메일 (중앙 정렬)
            userProfileAsync.when(
              data: (profile) => _buildCenteredUserInfo(
                context,
                profile,
                currentUser,
              ),
              loading: () => _buildSkeletonInfo(context),
              error: (_, __) => _buildCenteredUserInfo(
                context,
                null,
                currentUser,
              ),
            ),

            const SizedBox(height: common.Spacing.xl),

            // 2x2 통계 그리드
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  // Fragment (좌측, 1x2)
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () => context.go('/timeline'),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              AppIcons.fileText,
                              size: 40,
                              color: colorScheme.onPrimary,
                            ),
                            const SizedBox(height: common.Spacing.md),
                            fragmentCountAsync.when(
                              data: (count) => Text(
                                count.toString(),
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              loading: () => SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                              error: (_, __) => Text(
                                '0',
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: common.Spacing.xs),
                            Text(
                              'timeline.fragments'.tr(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimary.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: common.Spacing.md),

                  // Draft + Post (우측)
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        // Draft (상단)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.go('/drafts'),
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    AppIcons.edit,
                                    size: 24,
                                    color: colorScheme.onSurface,
                                  ),
                                  const SizedBox(width: common.Spacing.sm),
                                  draftCountsAsync.when(
                                    data: (counts) => Text(
                                      counts['all'].toString(),
                                      style:
                                          theme.textTheme.headlineLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    loading: () => const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    error: (_, __) => Text(
                                      '0',
                                      style:
                                          theme.textTheme.headlineLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: common.Spacing.md),

                        // Post (하단)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.go('/posts'),
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    AppIcons.send,
                                    size: 24,
                                    color: colorScheme.onSurface,
                                  ),
                                  const SizedBox(width: common.Spacing.sm),
                                  postCountAsync.when(
                                    data: (count) => Text(
                                      count.toString(),
                                      style:
                                          theme.textTheme.headlineLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    loading: () => const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    error: (_, __) => Text(
                                      '0',
                                      style:
                                          theme.textTheme.headlineLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildProfileAvatar(
    BuildContext context,
    Map<String, dynamic>? profile,
    dynamic currentUser, {
    required double size,
  }) {
    if (profile?['photo_url'] != null && currentUser != null) {
      final photoUrl = profile!['photo_url'] as String;
      final userId = currentUser.id;

      final fullUrl = StorageUtils.getUserPhotoUrl(userId, photoUrl);

      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(fullUrl),
        backgroundColor: ShadTheme.of(context).colorScheme.surfaceContainerHighest,
      );
    }

    return _buildDefaultAvatar(context, size: size);
  }

  Widget _buildDefaultAvatar(BuildContext context, {required double size}) {
    final colorScheme = ShadTheme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
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
        size: size * 0.5,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildSkeletonAvatar(BuildContext context, {required double size}) {
    final colorScheme = ShadTheme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCenteredUserInfo(
    BuildContext context,
    Map<String, dynamic>? profile,
    dynamic currentUser,
  ) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isLoggedIn = currentUser != null;

    final userName = isLoggedIn
        ? (profile?['name'] ??
            currentUser.email?.split('@')[0] ??
            'common.user'.tr())
        : 'auth.guest'.tr();

    final userEmail = isLoggedIn
        ? (currentUser.email ?? '')
        : 'auth.login_required_message'.tr();

    return Column(
      children: [
        Text(
          userName,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: common.Spacing.xs),
        Text(
          userEmail,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSkeletonInfo(BuildContext context) {
    final colorScheme = ShadTheme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          height: 24,
          width: 120,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: common.Spacing.xs),
        Container(
          height: 16,
          width: 160,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

/// ========================================
/// Variant 2: Bear 스타일 (미니멀)
/// ========================================
class _BearStyleProfile extends ConsumerWidget {
  const _BearStyleProfile();

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
            // 프로필 이미지 (ShadAvatar 사용)
            GestureDetector(
              onTap: isLoggedIn
                  ? () => context.push('/profile')
                  : () => context.push('/auth'),
              child: userProfileAsync.when(
                data: (profile) => _buildProfileAvatar(
                  context,
                  profile,
                  currentUser,
                ),
                loading: () => SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
                error: (_, __) => _buildProfileAvatar(context, null, currentUser),
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
                    AppIcons.fileText,
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
                    AppIcons.edit,
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
                    AppIcons.send,
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
    Map<String, dynamic>? profile,
    dynamic currentUser,
  ) {
    final colorScheme = ShadTheme.of(context).colorScheme;

    String? imageUrl;
    if (profile?['photo_url'] != null && currentUser != null) {
      final photoUrl = profile!['photo_url'] as String;
      final userId = currentUser.id;

      imageUrl = StorageUtils.getUserPhotoUrl(userId, photoUrl);
    }

    return ShadAvatar(
      imageUrl ?? '',
      size: const Size.square(80),
      placeholder: Container(
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
          size: 40,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// ========================================
/// Variant 3: Notion 스타일 (혼합형)
/// ========================================
class _NotionStyleProfile extends ConsumerWidget {
  const _NotionStyleProfile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final isLoggedIn = currentUser != null;

    final fragmentCountAsync = ref.watch(fragmentCountProvider);
    final draftCountsAsync = ref.watch(draftCountsProvider);
    final postCountAsync = ref.watch(postsCountProvider);

    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: common.Spacing.md),
      child: Column(
        children: [
          // 상단: 가로 배치 (프로필 + 정보 + 통계 요약)
          ShadCard(
            child: InkWell(
              onTap: isLoggedIn
                  ? () => context.push('/profile')
                  : () => context.push('/auth'),
              child: Row(
                children: [
                  // 프로필 이미지
                  userProfileAsync.when(
                    data: (profile) => _buildProfileAvatar(
                      context,
                      profile,
                      currentUser,
                      size: 64,
                    ),
                    loading: () => _buildSkeletonAvatar(context, size: 64),
                    error: (_, __) => _buildDefaultAvatar(context, size: 64),
                  ),

                  const SizedBox(width: common.Spacing.md),

                  // 이름 + 이메일
                  Expanded(
                    child: userProfileAsync.when(
                      data: (profile) => _buildUserInfo(
                        context,
                        profile,
                        currentUser,
                      ),
                      loading: () => _buildSkeletonInfo(context),
                      error: (_, __) => _buildUserInfo(
                        context,
                        null,
                        currentUser,
                      ),
                    ),
                  ),

                  const SizedBox(width: common.Spacing.sm),

                  // 통계 요약 배지
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: common.Spacing.sm,
                      vertical: common.Spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        fragmentCountAsync.maybeWhen(
                          data: (count) => Text(
                            count.toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          orElse: () => const Text('0'),
                        ),
                        const Text(' · '),
                        draftCountsAsync.maybeWhen(
                          data: (counts) => Text(
                            counts['all'].toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          orElse: () => const Text('0'),
                        ),
                        const Text(' · '),
                        postCountAsync.maybeWhen(
                          data: (count) => Text(
                            count.toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          orElse: () => const Text('0'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: common.Spacing.md),

          // 하단: 2x2 통계 그리드
          SizedBox(
            height: 140,
            child: Row(
              children: [
                // Fragment (좌측, 1x2)
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () => context.go('/timeline'),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            AppIcons.fileText,
                            size: 32,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: common.Spacing.sm),
                          fragmentCountAsync.when(
                            data: (count) => Text(
                              count.toString(),
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            loading: () => SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                            error: (_, __) => Text('0', style: Theme.of(context).textTheme.displayMedium),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: common.Spacing.md),

                // Draft + Post (우측)
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // Draft
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.go('/drafts'),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: colorScheme.outline,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(AppIcons.edit, size: 20),
                                const SizedBox(width: common.Spacing.xs),
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
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: common.Spacing.md),

                      // Post
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.go('/posts'),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: colorScheme.outline,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(AppIcons.send, size: 20),
                                const SizedBox(width: common.Spacing.xs),
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(
    BuildContext context,
    Map<String, dynamic>? profile,
    dynamic currentUser, {
    required double size,
  }) {
    if (profile?['photo_url'] != null && currentUser != null) {
      final photoUrl = profile!['photo_url'] as String;
      final userId = currentUser.id;

      final fullUrl = StorageUtils.getUserPhotoUrl(userId, photoUrl);

      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(fullUrl),
        backgroundColor: ShadTheme.of(context).colorScheme.surfaceContainerHighest,
      );
    }

    return _buildDefaultAvatar(context, size: size);
  }

  Widget _buildDefaultAvatar(BuildContext context, {required double size}) {
    final colorScheme = ShadTheme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
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
        size: size * 0.5,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildSkeletonAvatar(BuildContext context, {required double size}) {
    final colorScheme = ShadTheme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildUserInfo(
    BuildContext context,
    Map<String, dynamic>? profile,
    dynamic currentUser,
  ) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    final isLoggedIn = currentUser != null;

    final userName = isLoggedIn
        ? (profile?['name'] ??
            currentUser.email?.split('@')[0] ??
            'common.user'.tr())
        : 'auth.guest'.tr();

    final userEmail = isLoggedIn
        ? (currentUser.email ?? '')
        : 'auth.login_required_message'.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          userName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          userEmail,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSkeletonInfo(BuildContext context) {
    final colorScheme = ShadTheme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 20,
          width: 100,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 14,
          width: 140,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
