import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/database/database_service.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../models/draft.dart';
import '../../../../models/fragment.dart';
import '../../../../shared/widgets/standard_bottom_sheet.dart';
import 'draft_card_actions.dart';

/// Draft 카드 위젯
class DraftCard extends ConsumerStatefulWidget {
  final Draft draft;
  final VoidCallback? onUpdate;

  const DraftCard({required this.draft, this.onUpdate, super.key});

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('common.error'.tr())));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showDeleteDialog() async {
    final confirmed = await StandardBottomSheet.showConfirmation(
      context: context,
      title: 'draft.delete_title'.tr(),
      message: 'draft.delete_confirm'.tr(),
      confirmText: 'common.delete'.tr(),
      isDestructive: true,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('common.error'.tr())));
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

    return ShadCard(
      padding: EdgeInsets.zero,
      footer: Padding(
        padding: EdgeInsets.fromLTRB(common.Spacing.md, common.Spacing.sm, 0, common.Spacing.sm),
        child: DraftCardActions(
          status: widget.draft.status,
          isLoading: _isLoading,
          hasSubmittedFeedback: _hasSubmittedFeedback,
          draftRemoteID: widget.draft.remoteID,
          onAccept: () => _updateStatus('accepted'),
          onReject: () => _updateStatus('rejected'),
          onDelete: _showDeleteDialog,
          onFeedback: _showFeedbackDialog,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(common.Spacing.md),
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
                          SizedBox(height: common.Spacing.xs),
                          Text(
                            widget.draft.reason!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: theme.colorScheme.mutedForeground,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: common.Spacing.sm),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: common.Spacing.sm,
                      vertical: common.Spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius: BorderRadius.circular(common.Spacing.xs),
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

              SizedBox(height: common.Spacing.sm + common.Spacing.xs),

              // Fragment 개수 & 유사도
              Row(
                children: [
                  Icon(
                    AppIcons.file,
                    size: 14,
                    color: theme.colorScheme.mutedForeground,
                  ),
                  SizedBox(width: common.Spacing.xs),
                  Text(
                    'draft.snap_count'.tr(
                      namedArgs: {'count': _fragments.length.toString()},
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                  if (widget.draft.similarityScore != null) ...[
                    SizedBox(width: common.Spacing.sm),
                    Text(
                      '•',
                      style: TextStyle(
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                    SizedBox(width: common.Spacing.sm),
                    Text(
                      '${'draft.similarity'.tr()} ${(widget.draft.similarityScore! * 100).round()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: common.Spacing.sm + common.Spacing.xs),

              // Fragment 목록 토글
              ShadButton.ghost(
                onPressed: () =>
                    setState(() => _showFragments = !_showFragments),
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showFragments
                          ? AppIcons.chevronDown
                          : AppIcons.chevronRight,
                      size: 16,
                    ),
                    SizedBox(width: common.Spacing.xs + 2),
                    Text(
                      _showFragments
                          ? 'draft.toggle_snaps_hide'.tr()
                          : 'draft.toggle_snaps_show'.tr(),
                    ),
                  ],
                ),
              ),

              if (_showFragments) ...[
                SizedBox(height: common.Spacing.sm + common.Spacing.xs),
                Container(
                  padding: EdgeInsets.only(left: common.Spacing.sm + common.Spacing.xs),
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
                        margin: EdgeInsets.only(bottom: common.Spacing.sm),
                        padding: EdgeInsets.all(common.Spacing.sm + common.Spacing.xs),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.muted,
                          borderRadius: BorderRadius.circular(common.Spacing.sm),
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
                            SizedBox(height: common.Spacing.xs),
                            Text(
                              DateFormat(
                                'MMM d, HH:mm',
                              ).format(fragment.eventTime),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
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
          ],
        ),
      ),
    );
  }
}
