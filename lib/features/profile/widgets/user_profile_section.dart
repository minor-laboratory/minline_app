import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/utils/app_icons.dart';
import '../../auth/providers/auth_provider.dart';

/// 사용자 프로필 카드 위젯 (설정 페이지 상단)
class UserProfileSection extends ConsumerWidget {
  const UserProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final isLoggedIn = currentUser != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: common.Spacing.md),
      child: ShadCard(
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
                ),
                loading: () => _buildSkeletonAvatar(context),
                error: (error, stackTrace) => _buildDefaultAvatar(context),
              ),

              const SizedBox(width: common.Spacing.lg),

              // 사용자 정보
              Expanded(
                child: userProfileAsync.when(
                  data: (profile) => _buildUserInfo(
                    context,
                    profile,
                    currentUser,
                  ),
                  loading: () => _buildSkeletonInfo(context),
                  error: (error, stackTrace) =>
                      _buildUserInfo(context, null, currentUser),
                ),
              ),

              const SizedBox(width: common.Spacing.md),

              // 액션 아이콘
              ShadCard(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isLoggedIn ? AppIcons.edit : AppIcons.login,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(
    BuildContext context,
    Map<String, dynamic>? profile,
    dynamic currentUser,
  ) {
    if (profile?['photo_url'] != null && currentUser != null) {
      final photoUrl = profile!['photo_url'] as String;
      final userId = currentUser.id;

      // Supabase Storage URL 생성
      final fullUrl = photoUrl.startsWith('http')
          ? photoUrl
          : 'https://your-project.supabase.co/storage/v1/object/public/users/$userId/$photoUrl';

      return CircleAvatar(
        radius: 32,
        backgroundImage: NetworkImage(fullUrl),
        backgroundColor: ShadTheme.of(context).colorScheme.surfaceContainerHighest,
        onBackgroundImageError: (exception, stackTrace) {
          // 이미지 로드 실패 시 기본 아바타로 대체
        },
      );
    }

    return _buildDefaultAvatar(context);
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    final colorScheme = ShadTheme.of(context).colorScheme;

    return Container(
      width: 64,
      height: 64,
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
        size: 32,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildSkeletonAvatar(BuildContext context) {
    final colorScheme = ShadTheme.of(context).colorScheme;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest,
      ),
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: colorScheme.primary,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 사용자 이름
        Text(
          userName,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: common.Spacing.xs),

        // 이메일 또는 로그인 안내
        Text(
          userEmail,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
        ),

        // 인증 상태 뱃지 (로그인 사용자만)
        if (isLoggedIn) ...[
          const SizedBox(height: common.Spacing.xs),
          Row(
            children: [
              Icon(AppIcons.check, size: 14, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                'auth.verified_account'.tr(),
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSkeletonInfo(BuildContext context) {
    final colorScheme = ShadTheme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이름 스켈레톤
        Container(
          height: 20,
          width: 120,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        const SizedBox(height: common.Spacing.xs),

        // 이메일 스켈레톤
        Container(
          height: 16,
          width: 160,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        const SizedBox(height: common.Spacing.xs),

        // 상태 스켈레톤
        Container(
          height: 14,
          width: 80,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
