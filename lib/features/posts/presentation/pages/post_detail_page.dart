import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/database/database_service.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/utils/logger.dart';
import '../../../../models/fragment.dart';
import '../../../../models/post.dart';
import '../../../timeline/presentation/widgets/fragment_card.dart';

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
  List<Fragment> _fragments = [];
  bool _showFragments = false;
  String _viewMode = 'preview'; // 'preview' | 'source'

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

      // Fragment 로드
      List<Fragment> fragments = [];
      if (post != null && post.fragmentIds.isNotEmpty) {
        for (final fragmentId in post.fragmentIds) {
          final fragment = await isar.fragments.getByRemoteID(fragmentId);
          if (fragment != null) {
            fragments.add(fragment);
          }
        }
      }

      if (mounted) {
        setState(() {
          _post = post;
          _fragments = fragments;
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

  /// Markdown 파일로 내보내기
  Future<void> _handleExport() async {
    if (_post == null) return;

    try {
      // Markdown 내용 생성
      final markdown = '# ${_post!.title}\n\n${_post!.content}';

      // 임시 파일 생성
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${_post!.title}.md');
      await file.writeAsString(markdown);

      // 공유
      await Share.shareXFiles(
        [XFile(file.path)],
        text: _post!.title,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('post.export_success'.tr())),
        );
      }
    } catch (e, stack) {
      logger.e('[PostDetail] Export failed', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('common.error'.tr())),
        );
      }
    }
  }

  /// Post 재생성
  Future<void> _handleRegenerate() async {
    if (_post == null || _post!.draftId == null) return;

    // 확인 다이얼로그
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('post.regenerate'.tr()),
        description: Text('post.regenerate_confirm'.tr()),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          ShadButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('post.regenerate'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Post 생성 페이지로 이동 (previousVersionId 포함)
      context.push(
        '/posts/create/${_post!.draftId}?previousVersionId=${_post!.remoteID}',
      );
    }
  }

  /// Post 피드백 제출
  Future<void> _handleFeedback() async {
    if (_post == null) return;

    // 이미 피드백을 제출했는지 확인
    final hasExisting = await FeedbackService.instance.checkExistingFeedback(
      targetType: 'post',
      targetId: _post!.remoteID,
    );

    if (hasExisting && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('feedback.error_already_submitted'.tr())),
      );
      return;
    }

    // 피드백 페이지로 이동
    if (mounted) {
      await context.push<bool>(
        '/feedback/post/${_post!.remoteID}',
      );
    }
  }

  String _getTemplateLabel(String template) {
    return 'posts.template_$template'.tr();
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
          // 내보내기 버튼
          ShadIconButton.ghost(
            icon: Icon(AppIcons.download),
            onPressed: _handleExport,
          ),
          // 더보기 메뉴
          PopupMenuButton<String>(
            padding: const EdgeInsets.all(4),
            iconSize: 18,
            icon: Icon(
              AppIcons.moreVert,
              color: ShadTheme.of(context).colorScheme.mutedForeground,
            ),
                onSelected: (value) {
                  switch (value) {
                    case 'regenerate':
                      _handleRegenerate();
                      break;
                    case 'feedback':
                      _handleFeedback();
                      break;
                    case 'delete':
                      _deletePost();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  // 재생성 (draftId가 있는 경우에만)
                  if (_post?.draftId != null)
                    PopupMenuItem(
                      value: 'regenerate',
                      child: Row(
                        children: [
                          Icon(AppIcons.refresh, size: 16),
                          const SizedBox(width: 8),
                          Text('post.regenerate'.tr()),
                        ],
                      ),
                    ),
                  // 피드백 신고
                  PopupMenuItem(
                    value: 'feedback',
                    child: Row(
                      children: [
                        Icon(AppIcons.flag, size: 16),
                        const SizedBox(width: 8),
                        Text('feedback.report_issue'.tr()),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  // 삭제
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(AppIcons.delete, size: 16, color: colorScheme.error),
                        const SizedBox(width: 8),
                        Text(
                          'common.delete'.tr(),
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
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
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Preview/Source 토글 버튼
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _viewMode == 'preview'
                      ? ShadButton(
                          onPressed: null,
                          size: ShadButtonSize.sm,
                          decoration: ShadDecoration(
                            border: ShadBorder(
                              radius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                            ),
                          ),
                          child: Text('post.show_preview'.tr()),
                        )
                      : ShadButton.outline(
                          onPressed: () => setState(() => _viewMode = 'preview'),
                          size: ShadButtonSize.sm,
                          decoration: ShadDecoration(
                            border: ShadBorder(
                              radius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                            ),
                          ),
                          child: Text('post.show_preview'.tr()),
                        ),
                  _viewMode == 'source'
                      ? ShadButton(
                          onPressed: null,
                          size: ShadButtonSize.sm,
                          decoration: ShadDecoration(
                            border: ShadBorder(
                              radius: BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                          ),
                          child: Text('post.show_source'.tr()),
                        )
                      : ShadButton.outline(
                          onPressed: () => setState(() => _viewMode = 'source'),
                          size: ShadButtonSize.sm,
                          decoration: ShadDecoration(
                            border: ShadBorder(
                              radius: BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                          ),
                          child: Text('post.show_source'.tr()),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 내용 (viewMode에 따라 렌더링)
            if (_viewMode == 'preview')
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
              )
            else
              Text(
                _post!.content,
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),

            const SizedBox(height: 24),

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

            // Fragment 목록 토글
            if (_fragments.isNotEmpty) ...[
              const SizedBox(height: 16),
              ShadButton.ghost(
                onPressed: () {
                  setState(() => _showFragments = !_showFragments);
                },
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showFragments ? AppIcons.chevronDown : AppIcons.chevronRight,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'draft.snap_count'.tr(
                        namedArgs: {'count': _fragments.length.toString()},
                      ),
                    ),
                  ],
                ),
              ),

              // Fragment 목록
              if (_showFragments) ...[
                const SizedBox(height: 12),
                ..._fragments.map((fragment) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FragmentCard(
                      fragment: fragment,
                      onUpdate: () {
                        // Post 상세 화면에서는 Fragment 수정 불가
                      },
                    ),
                  );
                }),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
