import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/database/database_service.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../models/post.dart';

/// Post 카드 위젯
class PostCard extends ConsumerStatefulWidget {
  final Post post;
  final VoidCallback? onUpdate;
  final VoidCallback? onTap;

  const PostCard({
    required this.post,
    this.onUpdate,
    this.onTap,
    super.key,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _isLoading = false;

  Future<void> _showDeleteDialog() async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('post.delete_title'.tr()),
        description: Text('post.delete_confirm'.tr()),
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

    if (confirmed == true) {
      _deletePost();
    }
  }

  Future<void> _deletePost() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final isar = DatabaseService.instance.isar;

      await isar.writeTxn(() async {
        final post = await isar.posts.get(widget.post.id);
        if (post != null) {
          post.deleted = true;
          post.synced = false;
          post.refreshAt = DateTime.now();
          await isar.posts.put(post);
        }
      });

      widget.onUpdate?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('common.error'.tr())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getContentPreview() {
    final content = widget.post.content;
    if (content.length > 150) {
      return '${content.substring(0, 150)}...';
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ShadCard(
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 & 공개 여부
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.post.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.post.isPublic)
                    ShadBadge(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppIcons.language, size: 12),
                          const SizedBox(width: 4),
                          Text('post.public'.tr()),
                        ],
                      ),
                    )
                  else
                    ShadBadge.outline(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppIcons.password, size: 12),
                          const SizedBox(width: 4),
                          Text('post.private'.tr()),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // 내용 미리보기
              Text(
                _getContentPreview(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Fragment 개수, 날짜, 템플릿
              Row(
                children: [
                  Icon(
                    AppIcons.file,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'post.snap_count'.tr(namedArgs: {
                      'count': widget.post.fragmentIds.length.toString(),
                    }),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM d').format(widget.post.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (widget.post.exportedTo.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      AppIcons.share,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'post.exported'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                    ),
                  ],
                ],
              ),

              const ShadSeparator.horizontal(),
              const SizedBox(height: 12),

              // 액션 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ShadIconButton.ghost(
                    icon: Icon(AppIcons.delete, size: 16),
                    onPressed: _isLoading ? null : _showDeleteDialog,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
