import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/utils/app_icons.dart';
import '../../providers/posts_provider.dart';
import 'post_card.dart';

/// Posts View (body만)
///
/// 완성된 글 목록을 표시
class PostsView extends ConsumerStatefulWidget {
  const PostsView({super.key});

  @override
  ConsumerState<PostsView> createState() => _PostsViewState();
}

class _PostsViewState extends ConsumerState<PostsView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final postsStream = ref.watch(postsStreamProvider);

    return postsStream.when(
      data: (posts) {
        if (posts.isEmpty) {
          final theme = ShadTheme.of(context);
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(common.Spacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.posts,
                    size: 64,
                    color: theme.colorScheme.border,
                  ),
                  const SizedBox(height: common.Spacing.md),
                  Text(
                    'posts.empty_title'.tr(),
                    style: theme.textTheme.h3,
                  ),
                  const SizedBox(height: common.Spacing.sm),
                  Text(
                    'posts.empty_message'.tr(),
                    style: theme.textTheme.muted,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(postsStreamProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(common.Spacing.md),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                post: post,
                onUpdate: () {
                  ref.invalidate(postsStreamProvider);
                },
                onTap: () {
                  context.push('/posts/${post.remoteID}');
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) {
        final theme = ShadTheme.of(context);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(common.Spacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  AppIcons.error,
                  size: 64,
                  color: theme.colorScheme.destructive,
                ),
                const SizedBox(height: common.Spacing.md),
                Text(
                  'timeline.error_title'.tr(),
                  style: theme.textTheme.h3,
                ),
                const SizedBox(height: common.Spacing.sm),
                Text(
                  error.toString(),
                  style: theme.textTheme.muted,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
