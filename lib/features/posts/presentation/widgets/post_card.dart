import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
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
      margin: EdgeInsets.only(bottom: common.Spacing.sm + common.Spacing.xs),
      child: ShadCard(
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(common.Spacing.sm + common.Spacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                widget.post.title,
                style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),

              SizedBox(height: common.Spacing.sm + common.Spacing.xs),

              // 내용 미리보기
              Text(
                _getContentPreview(),
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: common.Spacing.sm + common.Spacing.xs),

              // Fragment 개수, 날짜, 템플릿
              Row(
                children: [
                  Icon(
                    AppIcons.file,
                    size: 14,
                    color: theme.colorScheme.mutedForeground,
                  ),
                  SizedBox(width: common.Spacing.xs),
                  Text(
                    'post.snap_count'.tr(namedArgs: {
                      'count': widget.post.fragmentIds.length.toString(),
                    }),
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.mutedForeground,
                        ),
                  ),
                  SizedBox(width: common.Spacing.sm),
                  Text(
                    '•',
                    style: TextStyle(color: theme.colorScheme.mutedForeground),
                  ),
                  SizedBox(width: common.Spacing.sm),
                  Text(
                    DateFormat.yMMMd(context.locale.languageCode).format(widget.post.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.mutedForeground,
                        ),
                  ),
                  SizedBox(width: common.Spacing.sm),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: common.Spacing.sm, vertical: common.Spacing.xs),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.muted,
                      borderRadius: BorderRadius.circular(common.Spacing.xs),
                    ),
                    child: Text(
                      'posts.template_${widget.post.template}'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.mutedForeground,
                          ),
                    ),
                  ),
                  if (widget.post.exportedTo.isNotEmpty) ...[
                    SizedBox(width: common.Spacing.sm),
                    Text(
                      '•',
                      style: TextStyle(color: theme.colorScheme.mutedForeground),
                    ),
                    SizedBox(width: common.Spacing.sm),
                    Icon(
                      AppIcons.share,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: common.Spacing.xs),
                    Text(
                      'post.exported'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
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
