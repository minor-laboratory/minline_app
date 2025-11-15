import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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

  String _getContentPreview() {
    final content = widget.post.content;
    if (content.length > 150) {
      return '${content.substring(0, 150)}...';
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ShadCard(
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                widget.post.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),

              const SizedBox(height: 12),

              // 내용 미리보기
              Text(
                _getContentPreview(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.mutedForeground,
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
                    color: theme.colorScheme.mutedForeground,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'post.snap_count'.tr(namedArgs: {
                      'count': widget.post.fragmentIds.length.toString(),
                    }),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.mutedForeground,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•',
                    style: TextStyle(color: theme.colorScheme.mutedForeground),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat.yMMMd(context.locale.languageCode).format(widget.post.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.mutedForeground,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.muted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'posts.template_${widget.post.template}'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.mutedForeground,
                          ),
                    ),
                  ),
                  if (widget.post.exportedTo.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: theme.colorScheme.mutedForeground),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      AppIcons.share,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'post.exported'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                    ),
                  ],
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}
