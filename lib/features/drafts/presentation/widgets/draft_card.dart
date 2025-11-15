import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/database/database_service.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../models/draft.dart';
import '../../../../models/fragment.dart';
import 'draft_card_actions.dart';

/// Draft 카드 위젯
class DraftCard extends ConsumerStatefulWidget {
  final Draft draft;
  final VoidCallback? onUpdate;

  const DraftCard({
    required this.draft,
    this.onUpdate,
    super.key,
  });

  @override
  ConsumerState<DraftCard> createState() => _DraftCardState();
}

class _DraftCardState extends ConsumerState<DraftCard> {
  List<Fragment> _fragments = [];
  bool _showFragments = false;
  bool _isLoading = false;
  bool _hasSubmittedFeedback = false;

  @override
  void initState() {
    super.initState();
    _loadFragments();
    _markAsViewed();
    _checkFeedback();
  }

  Future<void> _checkFeedback() async {
    final hasSubmitted = await FeedbackService.instance.checkExistingFeedback(
      targetType: 'draft',
      targetId: widget.draft.remoteID,
    );

    if (mounted) {
      setState(() => _hasSubmittedFeedback = hasSubmitted);
    }
  }

  Future<void> _loadFragments() async {
    final isar = DatabaseService.instance.isar;

    // Fragment ID로 조회
    final fragments = <Fragment>[];
    for (final fragmentId in widget.draft.fragmentIds) {
      final fragment = await isar.fragments.getByRemoteID(fragmentId);

      if (fragment != null) {
        fragments.add(fragment);
      }
    }

    if (mounted) {
      setState(() => _fragments = fragments);
    }
  }

  Future<void> _markAsViewed() async {
    if (widget.draft.viewed) return;

    final isar = DatabaseService.instance.isar;

    await isar.writeTxn(() async {
      final draft = await isar.drafts.get(widget.draft.id);
      if (draft != null) {
        draft.viewed = true;
        draft.synced = false; // 서버 동기화 필요
        await isar.drafts.put(draft);
      }
    });
  }

  Future<void> _updateStatus(String status) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final isar = DatabaseService.instance.isar;

      await isar.writeTxn(() async {
        final draft = await isar.drafts.get(widget.draft.id);
        if (draft != null) {
          draft.status = status;
          draft.synced = false;
          draft.refreshAt = DateTime.now();
          await isar.drafts.put(draft);
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

  Future<void> _showDeleteDialog() async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('draft.delete_title'.tr()),
        description: Text('draft.delete_confirm'.tr()),
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
      _deleteDraft();
    }
  }

  Future<void> _deleteDraft() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final isar = DatabaseService.instance.isar;

      await isar.writeTxn(() async {
        final draft = await isar.drafts.get(widget.draft.id);
        if (draft != null) {
          draft.deleted = true;
          draft.synced = false;
          draft.refreshAt = DateTime.now();
          await isar.drafts.put(draft);
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


  Future<void> _showFeedbackDialog() async {
    final result = await context.push<bool>(
      '/feedback/draft/${widget.draft.remoteID}',
    );

    if (result == true) {
      _checkFeedback();
    }
  }

  Color _getStatusColor() {
    final theme = ShadTheme.of(context);
    switch (widget.draft.status) {
      case 'pending':
        return theme.colorScheme.primary.withValues(alpha: 0.1);
      case 'accepted':
        return theme.colorScheme.secondary.withValues(alpha: 0.1);
      case 'rejected':
        return theme.colorScheme.muted;
      default:
        return theme.colorScheme.muted;
    }
  }

  Color _getStatusTextColor() {
    final theme = ShadTheme.of(context);
    switch (widget.draft.status) {
      case 'pending':
        return theme.colorScheme.primary;
      case 'accepted':
        return theme.colorScheme.secondary;
      case 'rejected':
        return theme.colorScheme.mutedForeground;
      default:
        return theme.colorScheme.mutedForeground;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 & 상태 & 더보기
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.draft.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (widget.draft.reason != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.draft.reason!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.mutedForeground,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'draft.status_${widget.draft.status}'.tr(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _getStatusTextColor(),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Fragment 개수 & 유사도
            Row(
              children: [
                Icon(
                  AppIcons.file,
                  size: 14,
                  color: theme.colorScheme.mutedForeground,
                ),
                const SizedBox(width: 4),
                Text(
                  'draft.snap_count'.tr(namedArgs: {
                    'count': _fragments.length.toString(),
                  }),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.mutedForeground,
                      ),
                ),
                if (widget.draft.similarityScore != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '•',
                    style: TextStyle(color: theme.colorScheme.mutedForeground),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${'draft.similarity'.tr()} ${(widget.draft.similarityScore! * 100).round()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.mutedForeground,
                        ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Fragment 목록 토글
            ShadButton.ghost(
              onPressed: () => setState(() => _showFragments = !_showFragments),
              padding: EdgeInsets.zero,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showFragments ? AppIcons.chevronDown : AppIcons.chevronRight,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showFragments
                        ? 'draft.toggle_snaps_hide'.tr()
                        : 'draft.toggle_snaps_show'.tr(),
                  ),
                ],
              ),
            ),

            if (_showFragments) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.border,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _fragments.map((fragment) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.muted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fragment.content,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, HH:mm').format(fragment.eventTime),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.mutedForeground,
                                ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const Divider(height: 24),

            // 액션 버튼
            DraftCardActions(
              status: widget.draft.status,
              isLoading: _isLoading,
              hasSubmittedFeedback: _hasSubmittedFeedback,
              draftRemoteID: widget.draft.remoteID,
              onAccept: () => _updateStatus('accepted'),
              onReject: () => _updateStatus('rejected'),
              onDelete: _showDeleteDialog,
              onFeedback: _showFeedbackDialog,
            ),
          ],
        ),
      ),
    );
  }
}
