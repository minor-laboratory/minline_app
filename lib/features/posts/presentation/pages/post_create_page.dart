import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/post_templates.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/utils/logger.dart';
import '../../../../models/draft.dart';
import '../../../../models/fragment.dart';

/// Post 생성 페이지
///
/// Draft를 기반으로 완성된 글을 생성
class PostCreatePage extends ConsumerStatefulWidget {
  final String draftId;
  final String? previousVersionId; // 재생성 시 이전 버전 ID

  const PostCreatePage({
    required this.draftId,
    this.previousVersionId,
    super.key,
  });

  @override
  ConsumerState<PostCreatePage> createState() => _PostCreatePageState();
}

class _PostCreatePageState extends ConsumerState<PostCreatePage> {
  Draft? _draft;
  bool _isLoading = true;
  String _selectedTemplate = 'essay';

  // AI 생성 상태
  bool _isGenerating = false;
  String _generatingTitle = '';
  String _generatingContent = '';
  double _progress = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    try {
      final isar = DatabaseService.instance.isar;
      final draft = await isar.drafts.getByRemoteID(widget.draftId);

      if (mounted) {
        setState(() {
          _draft = draft;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      logger.e('Draft 로드 실패:', e, stack);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// AI 스트리밍으로 Post 생성
  Future<void> _handleGenerate() async {
    if (_isGenerating || _draft == null) return;

    setState(() {
      _isGenerating = true;
      _generatingTitle = '';
      _generatingContent = '';
      _progress = 0.0;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final isar = DatabaseService.instance.isar;

      // Fragment 로드
      final fragments = <Fragment>[];
      for (final fragmentId in _draft!.fragmentIds) {
        final fragment = await isar.fragments.getByRemoteID(fragmentId);
        if (fragment != null) {
          fragments.add(fragment);
        }
      }

      // 검증
      if (fragments.length < 2) {
        setState(() {
          _errorMessage = 'post.not_enough_fragments'.tr();
          _isGenerating = false;
        });
        return;
      }

      // Edge Function 호출 (SSE)
      final body = {
        'draftId': _draft!.remoteID,
        'fragmentIds': fragments.map((f) => f.remoteID).toList(),
        'template': _selectedTemplate,
      };

      // 재생성인 경우 previousVersionId 추가
      if (widget.previousVersionId != null) {
        body['previousVersionId'] = widget.previousVersionId!;
      }

      final response = await supabase.functions.invoke(
        'generate-post',
        body: body,
        headers: {'Accept': 'text/event-stream'},
      );

      if (response.status != 200) {
        throw Exception('generate-post failed: ${response.data}');
      }

      // SSE 스트림 파싱
      String? postId;

      // ByteStream을 String으로 변환
      String data;
      if (response.data is String) {
        data = response.data as String;
      } else if (response.data is ByteStream) {
        // Stream을 모두 읽어서 String으로 변환
        final stream = response.data as ByteStream;
        final bytes = await stream.toBytes();
        data = utf8.decode(bytes);
      } else {
        throw Exception('Unexpected response type: ${response.data.runtimeType}');
      }

      final lines = data.split('\n');

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final json = jsonDecode(line.substring(6)) as Map<String, dynamic>;

          if (json['type'] == 'title') {
            setState(() {
              _generatingTitle = json['content'] as String;
            });
          } else if (json['type'] == 'content') {
            setState(() {
              _generatingContent += json['content'] as String;
              _progress = (_progress + 1).clamp(0, 95);
            });
          } else if (json['type'] == 'done') {
            postId = json['postId'] as String;
            setState(() {
              _progress = 100;
            });
          } else if (json['type'] == 'error') {
            throw Exception(json['message']);
          }
        }
      }

      if (postId == null) {
        throw Exception('postId not received');
      }

      // Post 저장 (서버에서 이미 저장됨, 로컬 동기화 대기)
      await Future.delayed(const Duration(milliseconds: 500));

      // 상세 페이지로 이동
      if (mounted) {
        context.push('/posts/$postId');
      }
    } catch (e, stack) {
      logger.e('Post 생성 실패:', e, stack);
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('free_limit_exceeded')
              ? 'post.free_limit_exceeded'.tr()
              : 'post.generation_failed'.tr();
          _isGenerating = false;
        });
      }
    } finally {
      if (mounted && _isGenerating) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('post.create_title'.tr())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_draft == null) {
      return Scaffold(
        appBar: AppBar(title: Text('post.create_title'.tr())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                AppIcons.error,
                size: 64,
                color: ShadTheme.of(context).colorScheme.destructive,
              ),
              SizedBox(height: common.Spacing.md),
              Text(
                'post.draft_not_found'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('post.create_title'.tr()),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: common.Spacing.sm),
            child: ShadButton(
              onPressed: _isGenerating ? null : _handleGenerate,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isGenerating)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(AppIcons.sparkles, size: 16),
                  SizedBox(width: common.Spacing.sm),
                  Text(
                    _isGenerating
                        ? 'post.generating'.tr()
                        : 'post.generate'.tr(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(common.Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Draft 정보
            Card(
              child: Padding(
                padding: const EdgeInsets.all(common.Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          AppIcons.fileText,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: common.Spacing.sm),
                        Text(
                          'draft.title'.tr(),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    SizedBox(height: common.Spacing.sm + common.Spacing.xs),
                    Text(
                      _draft!.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (_draft!.reason != null) ...[
                      SizedBox(height: common.Spacing.sm),
                      Text(
                        _draft!.reason!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ShadTheme.of(context).colorScheme.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: common.Spacing.lg),

            // 템플릿 선택
            Text(
              'post.select_template'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: common.Spacing.sm + common.Spacing.xs),

            // 템플릿 그리드
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                childAspectRatio: 3.5,
                crossAxisSpacing: common.Spacing.sm + common.Spacing.xs,
                mainAxisSpacing: common.Spacing.sm + common.Spacing.xs,
              ),
              itemCount: PostTemplates.all.length,
              itemBuilder: (context, index) {
                final template = PostTemplates.all[index];
                return _buildTemplateCard(template);
              },
            ),

            SizedBox(height: common.Spacing.lg),

            // 미리보기 영역
            Text(
              'post.preview'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: common.Spacing.sm + common.Spacing.xs),

            // 에러 메시지
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: common.Spacing.sm + common.Spacing.xs),
                padding: const EdgeInsets.all(common.Spacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(common.Spacing.sm + common.Spacing.xs),
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.error,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    SizedBox(width: common.Spacing.sm + common.Spacing.xs),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 실시간 미리보기
            if (_isGenerating || _generatingContent.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(common.Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목
                      if (_generatingTitle.isNotEmpty) ...[
                        Text(
                          _generatingTitle,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: common.Spacing.md),
                        const Divider(),
                        SizedBox(height: common.Spacing.md),
                      ],

                      // 내용
                      if (_generatingContent.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _generatingContent,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            // 커서 애니메이션 (생성 중일 때만)
                            if (_isGenerating)
                              _CursorBlinker(
                                color: ShadTheme.of(context).colorScheme.primary,
                              ),
                          ],
                        ),

                      // 프로그레스바
                      if (_progress > 0 && _progress < 100) ...[
                        SizedBox(height: common.Spacing.md),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(common.Spacing.xs),
                          child: LinearProgressIndicator(
                            value: _progress / 100,
                            minHeight: 6,
                          ),
                        ),
                        SizedBox(height: common.Spacing.sm),
                        Text(
                          '${_progress.toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ShadTheme.of(
                                  context,
                                ).colorScheme.mutedForeground,
                              ),
                        ),
                      ],

                      // 완료 메시지
                      if (_progress >= 100) ...[
                        SizedBox(height: common.Spacing.md),
                        Row(
                          children: [
                            Icon(
                              AppIcons.checkCircle,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            SizedBox(width: common.Spacing.sm),
                            Text(
                              'post.generation_complete'.tr(),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              // 플레이스홀더
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(common.Spacing.md),
                  child: Center(
                    child: Text(
                      'post.preview_placeholder'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ShadTheme.of(context).colorScheme.mutedForeground,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(PostTemplate template) {
    final isSelected = _selectedTemplate == template.id;
    final theme = ShadTheme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedTemplate = template.id);
      },
      child: Card(
        color: isSelected ? theme.colorScheme.accent : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(common.Spacing.sm + common.Spacing.xs),
          side: isSelected
              ? BorderSide(color: theme.colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(common.Spacing.md),
          child: Row(
            children: [
              // 아이콘
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.muted,
                  borderRadius: BorderRadius.circular(common.Spacing.sm),
                ),
                child: Icon(
                  template.icon,
                  size: 24,
                  color: isSelected
                      ? theme.colorScheme.primaryForeground
                      : theme.colorScheme.mutedForeground,
                ),
              ),
              SizedBox(width: common.Spacing.md),
              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      template.nameKey.tr(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.accentForeground
                            : theme.colorScheme.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: common.Spacing.xs),
                    Text(
                      template.descKey.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.accentForeground.withValues(
                                alpha: 0.8,
                              )
                            : theme.colorScheme.mutedForeground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 체크 마크
              if (isSelected) ...[
                SizedBox(width: common.Spacing.sm),
                Icon(
                  AppIcons.checkCircle,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 커서 블링커 애니메이션
class _CursorBlinker extends StatefulWidget {
  final Color color;

  const _CursorBlinker({required this.color});

  @override
  State<_CursorBlinker> createState() => _CursorBlinkerState();
}

class _CursorBlinkerState extends State<_CursorBlinker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(width: 2, height: 20, color: widget.color),
    );
  }
}
