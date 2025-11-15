import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/database_service.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/utils/logger.dart';
import '../../../../models/draft.dart';
import '../../../../models/fragment.dart';

/// Fragment 카드 위젯 (웹 UX 완전 맞춤)
///
/// Timeline 화면에서 사용하는 개별 Fragment 카드
class FragmentCard extends ConsumerStatefulWidget {
  final Fragment fragment;
  final VoidCallback? onUpdate;
  final Function(String)? onTagClick;
  final Draft? draft;

  const FragmentCard({
    super.key,
    required this.fragment,
    this.onUpdate,
    this.onTagClick,
    this.draft,
  });

  @override
  ConsumerState<FragmentCard> createState() => _FragmentCardState();
}

class _FragmentCardState extends ConsumerState<FragmentCard> {
  bool _isEditing = false;
  bool _isLoading = false;
  final _editController = TextEditingController();
  final _tagController = TextEditingController();
  bool _isGeneratingEmbedding = false;
  bool _showAllTags = false; // 태그 전체 표시 여부

  @override
  void dispose() {
    _editController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  /// 편집 시작
  void _startEdit() {
    setState(() {
      _isEditing = true;
      _editController.text = widget.fragment.content;
    });
  }

  /// 편집 취소
  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _editController.clear();
    });
  }

  /// Fragment 업데이트
  Future<void> _handleUpdate() async {
    if (_editController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isar = DatabaseService.instance.isar;
      await isar.writeTxn(() async {
        widget.fragment.content = _editController.text.trim();
        widget.fragment.synced = false;
        widget.fragment.refreshAt = DateTime.now();
        await isar.fragments.put(widget.fragment);
      });

      setState(() => _isEditing = false);
      widget.onUpdate?.call();
    } catch (e, stack) {
      logger.e('Fragment 업데이트 실패', e, stack);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Fragment 삭제
  Future<void> _handleDelete() async {
    setState(() => _isLoading = true);

    try {
      final isar = DatabaseService.instance.isar;
      await isar.writeTxn(() async {
        widget.fragment.deleted = true;
        widget.fragment.synced = false;
        widget.fragment.refreshAt = DateTime.now();
        await isar.fragments.put(widget.fragment);
      });

      widget.onUpdate?.call();
    } catch (e, stack) {
      logger.e('Fragment 삭제 실패', e, stack);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 삭제 확인 Dialog
  void _showDeleteDialog() {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('snap.delete_title'.tr()),
        description: Text('snap.delete_confirm'.tr()),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ShadButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _handleDelete();
            },
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }

  /// 이미지 뷰어 표시
  void _showImageViewer(String url) {
    final imageProvider = CachedNetworkImageProvider(url);
    showImageViewer(
      context,
      imageProvider,
      swipeDismissible: true,
      doubleTapZoomable: true,
    );
  }

  /// 사용자 태그 추가 페이지로 이동
  Future<void> _showAddTagPage() async {
    logger.d('태그 추가 페이지 이동: ${widget.fragment.remoteID}');

    final tag = await context.push<String>('/tag/edit/${widget.fragment.remoteID}');

    logger.d('입력한 태그: $tag');
    if (tag == null || tag.isEmpty) {
      logger.d('태그 입력 취소됨');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isar = DatabaseService.instance.isar;
      logger.d('Isar 트랜잭션 시작 - Fragment ID: ${widget.fragment.id}');

      await isar.writeTxn(() async {
        // 트랜잭션 내부에서 다시 읽기 (Isar 필수)
        final fragment = await isar.fragments.get(widget.fragment.id);
        if (fragment == null) {
          logger.e('Fragment를 찾을 수 없음: ${widget.fragment.id}');
          return;
        }

        logger.d('현재 userTags: ${fragment.userTags}');

        if (!fragment.userTags.contains(tag)) {
          // ✅ Isar 리스트 수정: 새로운 리스트 생성하여 할당
          fragment.userTags = [...fragment.userTags, tag];
          fragment.synced = false;
          fragment.refreshAt = DateTime.now();
          await isar.fragments.put(fragment);
          logger.i('✅ 태그 추가 완료: $tag, 전체 태그: ${fragment.userTags}');
        } else {
          logger.d('이미 존재하는 태그: $tag');
        }
      });

      logger.d('onUpdate 호출');
      widget.onUpdate?.call();
    } catch (e, stack) {
      logger.e('태그 추가 실패', e, stack);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 사용자 태그 삭제
  Future<void> _handleRemoveUserTag(String tag) async {
    setState(() => _isLoading = true);

    try {
      final isar = DatabaseService.instance.isar;
      await isar.writeTxn(() async {
        // 트랜잭션 내부에서 다시 읽기 (Isar 필수)
        final fragment = await isar.fragments.get(widget.fragment.id);
        if (fragment == null) return;

        // ✅ Isar 리스트 수정: 새로운 리스트 생성하여 할당
        fragment.userTags = fragment.userTags.where((t) => t != tag).toList();
        fragment.synced = false;
        fragment.refreshAt = DateTime.now();
        await isar.fragments.put(fragment);
      });

      widget.onUpdate?.call();
    } catch (e, stack) {
      logger.e('태그 삭제 실패', e, stack);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// AI 태그 숨기기
  Future<void> _handleHideAiTag(String tag) async {
    setState(() => _isLoading = true);

    try {
      final isar = DatabaseService.instance.isar;
      await isar.writeTxn(() async {
        // 트랜잭션 내부에서 다시 읽기 (Isar 필수)
        final fragment = await isar.fragments.get(widget.fragment.id);
        if (fragment == null) return;

        // ✅ Isar 리스트 수정: 새로운 리스트 생성하여 할당
        fragment.tags = fragment.tags.where((t) => t != tag).toList();
        fragment.synced = false;
        fragment.refreshAt = DateTime.now();
        await isar.fragments.put(fragment);
      });

      widget.onUpdate?.call();
    } catch (e, stack) {
      logger.e('AI 태그 숨기기 실패', e, stack);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 이벤트 시간 Picker 표시 (Material BottomSheet)
  void _showEventTimePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EventTimePickerSheet(
        fragment: widget.fragment,
        onUpdate: (eventTime, eventTimeSource) async {
          await _handleEventTimeUpdate(eventTime, eventTimeSource);
        },
      ),
    );
  }

  /// 이벤트 시간 업데이트
  Future<void> _handleEventTimeUpdate(
      DateTime eventTime, String eventTimeSource) async {
    setState(() => _isLoading = true);

    try {
      final isar = DatabaseService.instance.isar;
      await isar.writeTxn(() async {
        widget.fragment.eventTime = eventTime;
        widget.fragment.eventTimeSource = eventTimeSource;
        widget.fragment.synced = false;
        widget.fragment.refreshAt = DateTime.now();
        await isar.fragments.put(widget.fragment);
      });

      widget.onUpdate?.call();
    } catch (e, stack) {
      logger.e('이벤트 시간 업데이트 실패', e, stack);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Embedding 생성 (Edge Function 호출)
  Future<void> _handleGenerateEmbedding() async {
    setState(() => _isGeneratingEmbedding = true);

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        logger.e('User not authenticated');
        return;
      }

      // Edge Function 호출 (30초 타임아웃)
      final response = await Supabase.instance.client.functions
          .invoke(
            'generate-embedding',
            body: {
              'id': widget.fragment.remoteID,
              'content': widget.fragment.content,
              'timestamp': widget.fragment.timestamp.toIso8601String(),
              'mediaUrls': widget.fragment.mediaUrls,
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Embedding generation timeout');
            },
          );

      if (response.status != 200) {
        throw Exception('Edge Function failed: ${response.data}');
      }

      logger.i('✅ Embedding 생성 완료: ${response.data}');

      // Realtime이 서버 변경 자동 감지하여 로컬 업데이트
      widget.onUpdate?.call();
    } catch (e, stack) {
      logger.e('Embedding 생성 오류', e, stack);
    } finally {
      if (mounted) {
        setState(() => _isGeneratingEmbedding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ShadCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 편집 모드
            if (_isEditing) ...[
              ShadTextarea(
                controller: _editController,
                minHeight: 100,
                maxHeight: 300,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ShadButton.outline(
                    onPressed: _isLoading ? null : _cancelEdit,
                    child: Text('common.cancel'.tr()),
                  ),
                  const SizedBox(width: 8),
                  ShadButton(
                    onPressed: _isLoading ? null : _handleUpdate,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('common.save'.tr()),
                  ),
                ],
              ),
            ] else ...[
              // 텍스트 내용
              if (widget.fragment.content.isNotEmpty) ...[
                Text(
                  widget.fragment.content,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: theme.colorScheme.foreground,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 이미지
              if (widget.fragment.mediaUrls.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.fragment.mediaUrls.map((url) {
                    return GestureDetector(
                      onTap: () => _showImageViewer(url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          width: 128,
                          height: 128,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 128,
                            height: 128,
                            color: theme.colorScheme.muted,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 128,
                            height: 128,
                            color: theme.colorScheme.muted,
                            child: Icon(
                              AppIcons.image,
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // 이벤트 시간 & 태그
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이벤트 시간
                  InkWell(
                    onTap: _showEventTimePicker,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getEventTimeIcon(widget.fragment.eventTimeSource),
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatEventTime(
                            context,
                            widget.fragment.eventTime,
                            widget.fragment.eventTimeSource,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 태그 (접기/펼치기 기능 포함)
                  const SizedBox(height: 8),
                  _buildTagsSection(context),
                ],
              ),

              // Draft 연결 정보
              if (widget.draft != null) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    // Draft 화면으로 이동 (push로 현재 화면 위에 추가)
                    context.push('/drafts');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppIcons.fileText,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'draft.linked_to'
                              .tr(namedArgs: {'title': widget.draft!.title}),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // 하단: 작성시간 & 동기화 상태 & 더보기
              const SizedBox(height: 12),
              Row(
                children: [
                  // 작성 시간
                  Icon(
                    AppIcons.fileText,
                    size: 12,
                    color: theme.colorScheme.mutedForeground,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(context, widget.fragment.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                  // 동기화 대기
                  if (!widget.fragment.synced) ...[
                    const SizedBox(width: 8),
                    Icon(
                      AppIcons.clock,
                      size: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                  const Spacer(),
                  // 더보기 메뉴 (PopupMenuButton) - 웹과 동일한 크기
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          AppIcons.moreVert,
                          size: 16,
                          color: theme.colorScheme.mutedForeground,
                        ),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _startEdit();
                            break;
                          case 'generate':
                            _handleGenerateEmbedding();
                            break;
                          case 'delete':
                            _showDeleteDialog();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(AppIcons.edit, size: 16),
                              const SizedBox(width: 8),
                              Text('common.edit'.tr()),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'generate',
                          enabled: !_isGeneratingEmbedding,
                          child: Row(
                            children: [
                              Icon(AppIcons.sparkles, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _isGeneratingEmbedding
                                    ? 'common.generating'.tr()
                                    : 'common.generate'.tr(),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(AppIcons.delete,
                                  size: 16, color: theme.colorScheme.destructive),
                              const SizedBox(width: 8),
                              Text(
                                'common.delete'.tr(),
                                style: TextStyle(color: theme.colorScheme.destructive),
                              ),
                            ],
                          ),
                        ),
                      ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 이벤트 시간 아이콘
  IconData _getEventTimeIcon(String source) {
    if (source.startsWith('ai')) {
      return AppIcons.sparkles; // AI 추론 시간
    } else if (source.startsWith('user')) {
      return AppIcons.calendar; // 사용자 설정 시간
    } else {
      return AppIcons.clock; // 자동 (작성 시간)
    }
  }

  /// 이벤트 시간 포맷
  String _formatEventTime(BuildContext context, DateTime date, String source) {
    final includeTime = source.contains('time') || source == 'auto';
    final now = DateTime.now();
    final diff = now.difference(date);

    // 상대 시간 (time variant만, 7일 이내)
    if (includeTime) {
      if (diff.inMinutes < 1) return 'time.just_now'.tr();
      if (diff.inMinutes < 60) {
        return 'time.minutes_ago'
            .tr(namedArgs: {'minutes': diff.inMinutes.toString()});
      }
      if (diff.inHours < 24) {
        return 'time.hours_ago'
            .tr(namedArgs: {'hours': diff.inHours.toString()});
      }
      if (diff.inDays < 7) {
        return 'time.days_ago'.tr(namedArgs: {'days': diff.inDays.toString()});
      }
    }

    // 절대 시간
    final locale = Localizations.localeOf(context).languageCode;
    final format =
        includeTime ? 'time.datetime_format'.tr() : 'time.date_format'.tr();
    return intl.DateFormat(format, locale).format(date);
  }

  /// 작성 시간 포맷 (항상 상대 시간)
  String _formatTimestamp(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'time.just_now'.tr();
    if (diff.inMinutes < 60) {
      return 'time.minutes_ago'
          .tr(namedArgs: {'minutes': diff.inMinutes.toString()});
    }
    if (diff.inHours < 24) {
      return 'time.hours_ago'
          .tr(namedArgs: {'hours': diff.inHours.toString()});
    }
    if (diff.inDays < 7) {
      return 'time.days_ago'.tr(namedArgs: {'days': diff.inDays.toString()});
    }

    final locale = Localizations.localeOf(context).languageCode;
    return intl.DateFormat('time.date_format'.tr(), locale).format(date);
  }

  /// 태그 섹션 (접기/펼치기 기능)
  Widget _buildTagsSection(BuildContext context) {
    final allTags = [
      ...widget.fragment.tags,
      ...widget.fragment.userTags,
    ];

    const maxVisibleTags = 4; // 접을 때 보여줄 최대 태그 수
    final hasMoreTags = allTags.length > maxVisibleTags;
    final visibleTags = _showAllTags ? allTags : allTags.take(maxVisibleTags).toList();
    final hiddenCount = allTags.length - maxVisibleTags;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        // AI 태그
        ...widget.fragment.tags.take(
          _showAllTags ? widget.fragment.tags.length :
          (visibleTags.length - widget.fragment.userTags.length).clamp(0, widget.fragment.tags.length)
        ).map((tag) => _buildAITag(context, tag)),

        // 사용자 태그
        ...widget.fragment.userTags.where((tag) => visibleTags.contains(tag))
          .map((tag) => _buildUserTag(context, tag)),

        // 더보기 버튼 (태그가 많을 때만)
        if (hasMoreTags)
          _buildToggleTagsButton(context, hiddenCount),

        // 태그 추가 버튼
        _buildAddTagButton(context),
      ],
    );
  }

  /// 태그 펼치기/접기 버튼
  Widget _buildToggleTagsButton(BuildContext context, int hiddenCount) {
    final theme = ShadTheme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _showAllTags = !_showAllTags;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.muted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          _showAllTags ? 'common.show_less'.tr() : 'common.show_more'.tr(namedArgs: {'count': '+$hiddenCount'}),
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.mutedForeground,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// AI 태그 위젯 (웹 스타일)
  Widget _buildAITag(BuildContext context, String tag) {
    final theme = ShadTheme.of(context);

    return GestureDetector(
      onTap: () => widget.onTagClick?.call(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.muted,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.sparkles, size: 12, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              tag,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _showHideAiTagSheet(tag),
              child: Icon(
                AppIcons.close,
                size: 12,
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// AI 태그 숨기기 BottomSheet
  void _showHideAiTagSheet(String tag) {
    final theme = ShadTheme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'tag.confirm_hide'.tr(namedArgs: {'tag': tag}),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('common.cancel'.tr()),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _handleHideAiTag(tag);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.destructive,
                    foregroundColor: theme.colorScheme.destructiveForeground,
                  ),
                  child: Text('tag.hide'.tr()),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 사용자 태그 위젯 (웹 스타일)
  Widget _buildUserTag(BuildContext context, String tag) {
    final theme = ShadTheme.of(context);

    return GestureDetector(
      onTap: () => widget.onTagClick?.call(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.edit, size: 12, color: theme.colorScheme.primaryForeground),
            const SizedBox(width: 4),
            Text(
              tag,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primaryForeground,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _showRemoveUserTagSheet(tag),
              child: Icon(
                AppIcons.close,
                size: 12,
                color: theme.colorScheme.primaryForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 사용자 태그 삭제 BottomSheet
  void _showRemoveUserTagSheet(String tag) {
    final theme = ShadTheme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'tag.confirm_remove'.tr(namedArgs: {'tag': tag}),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('common.cancel'.tr()),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _handleRemoveUserTag(tag);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.destructive,
                    foregroundColor: theme.colorScheme.destructiveForeground,
                  ),
                  child: Text('common.delete'.tr()),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 태그 추가 버튼 (웹 스타일)
  Widget _buildAddTagButton(BuildContext context) {
    final theme = ShadTheme.of(context);
    return GestureDetector(
      onTap: _showAddTagPage,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.muted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.add, size: 12, color: theme.colorScheme.mutedForeground),
            const SizedBox(width: 4),
            Text(
              'tag.add_tag'.tr(),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// 이벤트 시간 Picker Sheet (Material BottomSheet)
class _EventTimePickerSheet extends StatefulWidget {
  final Fragment fragment;
  final Function(DateTime, String) onUpdate;

  const _EventTimePickerSheet({
    required this.fragment,
    required this.onUpdate,
  });

  @override
  State<_EventTimePickerSheet> createState() => _EventTimePickerSheetState();
}

class _EventTimePickerSheetState extends State<_EventTimePickerSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late bool _includeTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.fragment.eventTime;
    _selectedTime = TimeOfDay.fromDateTime(widget.fragment.eventTime);
    _includeTime = _hasTime(widget.fragment.eventTimeSource);
  }

  bool _hasTime(String source) {
    return source == 'ai_time' || source == 'user_time' || source == 'auto';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);

    try {
      // 날짜 + 시간 결합
      final eventTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _includeTime ? _selectedTime.hour : 0,
        _includeTime ? _selectedTime.minute : 0,
        0,
      );

      // user가 수정하므로 user_date 또는 user_time으로 변경
      final eventTimeSource = _includeTime ? 'user_time' : 'user_date';

      await widget.onUpdate(eventTime, eventTimeSource);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final dateFormat = intl.DateFormat('time.date_format'.tr(), locale);
    final timeFormat = intl.DateFormat.Hm(locale);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            'time.event_time'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // 시간 포함 스위치
          SwitchListTile(
            title: Text('common.include_time'.tr()),
            value: _includeTime,
            onChanged: (value) {
              setState(() {
                _includeTime = value;
              });
            },
          ),
          const SizedBox(height: 8),

          // 날짜 선택
          ListTile(
            leading: Icon(AppIcons.calendar),
            title: Text(dateFormat.format(_selectedDate)),
            trailing: Icon(AppIcons.chevronRight),
            onTap: _pickDate,
          ),

          // 시간 선택 (시간 포함 모드일 때만)
          if (_includeTime) ...[
            ListTile(
              leading: Icon(AppIcons.clock),
              title: Text(timeFormat.format(
                DateTime(2000, 1, 1, _selectedTime.hour, _selectedTime.minute),
              )),
              trailing: Icon(AppIcons.chevronRight),
              onTap: _pickTime,
            ),
          ],

          const SizedBox(height: 16),

          // 저장/취소 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    _isLoading ? null : () => Navigator.of(context).pop(),
                child: Text('common.cancel'.tr()),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('common.save'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
