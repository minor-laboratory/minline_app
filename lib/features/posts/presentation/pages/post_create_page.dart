import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        headers: {
          'Accept': 'text/event-stream',
        },
      );

      if (response.status != 200) {
        throw Exception('generate-post failed: ${response.data}');
      }

      // SSE 스트림 파싱
      String? postId;
      final data = response.data as String;
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
        appBar: AppBar(
          title: Text('post.create_title'.tr()),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_draft == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('post.create_title'.tr()),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                AppIcons.error,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
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
            padding: const EdgeInsets.only(right: 8),
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
                  const SizedBox(width: 8),
                  Text(_isGenerating ? 'post.generating'.tr() : 'post.generate'.tr()),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Draft 정보
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                        const SizedBox(width: 8),
                        Text(
                          'draft.title'.tr(),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _draft!.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (_draft!.reason != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _draft!.reason!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 템플릿 선택
            Text(
              'post.select_template'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            // 템플릿 그리드
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                childAspectRatio: 3.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: PostTemplates.all.length,
              itemBuilder: (context, index) {
                final template = PostTemplates.all[index];
                return _buildTemplateCard(template);
              },
            ),

            const SizedBox(height: 24),

            // 미리보기 영역
            Text(
              'post.preview'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            // 에러 메시지
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.error,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목
                      if (_generatingTitle.isNotEmpty) ...[
                        Text(
                          _generatingTitle,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
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
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          ],
                        ),

                      // 프로그레스바
                      if (_progress > 0 && _progress < 100) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progress / 100,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_progress.toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],

                      // 완료 메시지
                      if (_progress >= 100) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              AppIcons.checkCircle,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'post.generation_complete'.tr(),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
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
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'post.preview_placeholder'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedTemplate = template.id);
      },
      child: Card(
        color: isSelected ? colorScheme.primaryContainer : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 아이콘
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  template.icon,
                  size: 24,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
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
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.descKey.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                                : colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 체크 마크
              if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(
                  AppIcons.checkCircle,
                  size: 20,
                  color: colorScheme.primary,
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

  const _CursorBlinker({
    required this.color,
  });

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
      child: Container(
        width: 2,
        height: 20,
        color: widget.color,
      ),
    );
  }
}
