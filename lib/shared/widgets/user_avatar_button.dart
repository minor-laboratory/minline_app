import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/utils/app_icons.dart';
import '../../core/utils/storage_utils.dart';
import '../../features/auth/providers/auth_provider.dart';

/// 사용자 아바타 버튼 (AppBar 우측)
///
/// 프로필 이미지 또는 기본 아이콘 표시
/// 클릭 시 설정 페이지로 이동
class UserAvatarButton extends ConsumerWidget {
  const UserAvatarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final theme = ShadTheme.of(context);

    return GestureDetector(
      onTap: () => context.push('/settings'),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: ClipOval(
          child: userProfileAsync.when(
            data: (profile) => _buildAvatar(
              context,
              theme,
              profile,
              currentUser,
            ),
            loading: () => _buildDefaultAvatar(theme),
            error: (_, __) => _buildDefaultAvatar(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    ShadThemeData theme,
    Map<String, dynamic>? profile,
    dynamic currentUser,
  ) {
    String? imageUrl;

    // userId가 실제로 존재하는 경우에만 이미지 로드
    if (profile?['photo_url'] != null &&
        currentUser != null &&
        currentUser.id != null &&
        currentUser.id.isNotEmpty) {
      final photoUrl = profile!['photo_url'] as String;
      final userId = currentUser.id;
      imageUrl = StorageUtils.getUserPhotoUrl(userId, photoUrl);
    }

    // 이미지가 있는 경우
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildDefaultAvatar(theme),
        errorWidget: (context, url, error) => _buildDefaultAvatar(theme),
      );
    }

    return _buildDefaultAvatar(theme);
  }

  Widget _buildDefaultAvatar(ShadThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.accent,
            theme.colorScheme.accent.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Icon(
        AppIcons.user,
        size: 18,
        color: theme.colorScheme.accentForeground,
      ),
    );
  }
}
