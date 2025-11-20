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
import '../../../../shared/widgets/standard_bottom_sheet.dart';

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

    // 미리보기 영역으로 스크롤 (부드럽게)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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

      // 상세 페이지로 이동 (현재 Create 페이지를 Detail로 교체)
      if (mounted) {
        context.pushReplacement('/posts/$postId');
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

  // 미리보기 영역으로 스크롤
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        controller: _scrollController,
        padding: const EdgeInsets.all(common.Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 미리보기 영역 (상단으로 이동)
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
                      // 로딩 상태 (생성 시작 직후, 아직 내용 없을 때)
                      if (_isGenerating && _generatingTitle.isEmpty && _generatingContent.isEmpty) ...[
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              ),
                              SizedBox(height: common.Spacing.md),
                              Text(
                                'post.generating_message'.tr(),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: ShadTheme.of(context).colorScheme.mutedForeground,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],

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

            SizedBox(height: common.Spacing.lg),

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

            SizedBox(height: common.Spacing.md),

            // 템플릿 선택 버튼
            _buildTemplateSelector(context),
          ],
        ),
      ),
    );
  }

  /// 템플릿 선택 버튼
  Widget _buildTemplateSelector(BuildContext context) {
    final theme = ShadTheme.of(context);
    final selectedTemplate = PostTemplates.all.firstWhere(
      (t) => t.id == _selectedTemplate,
    );

    return GestureDetector(
      onTap: _showTemplateSelector,
      child: Container(
        padding: const EdgeInsets.all(common.Spacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.muted,
          borderRadius: BorderRadius.circular(common.Spacing.sm),
          border: Border.all(
            color: theme.colorScheme.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selectedTemplate.icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: common.Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'post.select_template'.tr(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    selectedTemplate.nameKey.tr(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              AppIcons.chevronDown,
              size: 16,
              color: theme.colorScheme.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }

  /// 템플릿 선택 Bottom Sheet 표시
  Future<void> _showTemplateSelector() async {
    final result = await StandardBottomSheet.showSelection<String>(
      context: context,
      title: 'post.select_template'.tr(),
      selectedValue: _selectedTemplate,
      options: PostTemplates.all.map((template) {
        return BottomSheetOption<String>(
          text: template.nameKey.tr(),
          subtitle: template.descKey.tr(),
          value: template.id,
          icon: template.icon,
        );
      }).toList(),
    );

    if (result != null && mounted) {
      setState(() => _selectedTemplate = result);
    }
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
