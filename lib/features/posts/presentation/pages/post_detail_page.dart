import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar_community/isar.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/database/database_service.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/utils/logger.dart';
import '../../../../models/post.dart';

/// Post 상세 화면
class PostDetailPage extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  Post? _post;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    try {
      final isar = DatabaseService.instance.isar;
      final results = await isar.posts
          .filter()
          .remoteIDEqualTo(widget.postId)
          .findAll();
      final post = results.isNotEmpty ? results.first : null;

      if (mounted) {
        setState(() {
          _post = post;
          _isLoading = false;
        });

        // viewed = false → true 업데이트
        if (post != null && !post.viewed) {
          post.viewed = true;
          await isar.writeTxn(() => isar.posts.put(post));
        }
      }
    } catch (e, stack) {
      logger.e('[PostDetail] Failed to load post', e, stack);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deletePost() async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('posts.delete_confirm_title'.tr()),
        description: Text('posts.delete_confirm_message'.tr()),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final isar = DatabaseService.instance.isar;
        _post!.deleted = true;
        await isar.writeTxn(() => isar.posts.put(_post!));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('posts.deleted'.tr())),
          );
          context.pop();
        }
      } catch (e, stack) {
        logger.e('[PostDetail] Failed to delete post', e, stack);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('common.error'.tr())),
          );
        }
      }
    }
  }

  Future<void> _togglePublic() async {
    if (_post == null) return;

    try {
      final isar = DatabaseService.instance.isar;
      _post!.isPublic = !_post!.isPublic;
      await isar.writeTxn(() => isar.posts.put(_post!));

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _post!.isPublic
                  ? 'posts.made_public'.tr()
                  : 'posts.made_private'.tr(),
            ),
          ),
        );
      }
    } catch (e, stack) {
      logger.e('[PostDetail] Failed to toggle public', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('common.error'.tr())),
        );
      }
    }
  }

  String _getTemplateLabel(String template) {
    switch (template) {
      case 'product_review':
        return 'posts.template_product_review'.tr();
      case 'timeline':
        return 'posts.template_timeline'.tr();
      case 'essay':
        return 'posts.template_essay'.tr();
      case 'travel':
        return 'posts.template_travel'.tr();
      case 'project':
        return 'posts.template_project'.tr();
      default:
        return template;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: Text('posts.title'.tr())),
        body: Center(child: Text('posts.not_found'.tr())),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('posts.title'.tr()),
        actions: [
          ShadIconButton.ghost(
            icon: Icon(AppIcons.moreVert),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(AppIcons.delete),
                        title: Text('common.delete'.tr()),
                        onTap: () {
                          context.pop();
                          _deletePost();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Text(
              _post!.title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // 메타 정보
            Row(
              children: [
                // 템플릿 타입
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getTemplateLabel(_post!.template),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 작성일
                Text(
                  DateFormat('yyyy-MM-dd').format(_post!.createdAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const Spacer(),

                // 공개 여부
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _post!.isPublic ? AppIcons.language : AppIcons.password,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _post!.isPublic
                          ? 'posts.public'.tr()
                          : 'posts.private'.tr(),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // 내용 (Markdown)
            MarkdownBody(
              data: _post!.content,
              styleSheet: MarkdownStyleSheet(
                p: textTheme.bodyLarge,
                h1: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                h2: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                h3: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 공개 여부 토글
            Card(
              child: SwitchListTile(
                title: Text('posts.make_public'.tr()),
                subtitle: Text('posts.make_public_description'.tr()),
                value: _post!.isPublic,
                onChanged: (_) => _togglePublic(),
              ),
            ),

            // 버전 정보
            if (_post!.version > 1) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: Icon(AppIcons.star),
                  title: Text('posts.version'.tr()),
                  subtitle: Text('posts.version_info'.tr(
                    args: [_post!.version.toString()],
                  )),
                ),
              ),
            ],

            // 내보내기 정보
            if (_post!.exportedTo.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: Icon(AppIcons.share),
                  title: Text('posts.exported_to'.tr()),
                  subtitle: Text(_post!.exportedTo.join(', ')),
                ),
              ),
            ],

            // Fragment 개수
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(AppIcons.fileText),
                title: Text('posts.fragments_used'.tr()),
                subtitle: Text(
                  'posts.fragments_count'.tr(
                    args: [_post!.fragmentIds.length.toString()],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
