import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/utils/app_icons.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../../timeline/presentation/widgets/fragment_input_bar.dart';
import '../../providers/drafts_provider.dart';
import 'draft_card.dart';

/// Drafts View (body만)
///
/// AI가 생성한 초안 목록을 표시
class DraftsView extends ConsumerStatefulWidget {
  final String analyzeMessage;

  const DraftsView({super.key, this.analyzeMessage = ''});

  @override
  ConsumerState<DraftsView> createState() => _DraftsViewState();
}

class _DraftsViewState extends ConsumerState<DraftsView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final filter = ref.watch(draftFilterProvider);
    final draftsStream = ref.watch(draftsStreamProvider);
    final countsStream = ref.watch(draftCountsProvider);

    return Column(
      children: [
        // 분석 결과 메시지
        if (widget.analyzeMessage.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(common.Spacing.md),
            padding: const EdgeInsets.all(common.Spacing.md),
            decoration: BoxDecoration(
              color: ShadTheme.of(context).colorScheme.muted,
              borderRadius: BorderRadius.circular(common.BorderRadii.lg),
            ),
            child: Text(
              widget.analyzeMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),

        // Shadcn Tabs
        countsStream.when(
          data: (counts) => ShadTabs<String>(
            value: filter.status,
            onChanged: (value) {
              ref.read(draftFilterProvider.notifier).setStatus(value);
            },
            scrollable: true,
            tabs: [
              ShadTab(
                value: 'all',
                child: Text(
                  '${'draft.filter_all'.tr()} (${counts['all'] ?? 0})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ShadTab(
                value: 'pending',
                child: Text(
                  '${'draft.filter_pending'.tr()} (${counts['pending'] ?? 0})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ShadTab(
                value: 'accepted',
                child: Text(
                  '${'draft.filter_accepted'.tr()} (${counts['accepted'] ?? 0})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ShadTab(
                value: 'rejected',
                child: Text(
                  '${'draft.filter_rejected'.tr()} (${counts['rejected'] ?? 0})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // 탭 컨텐츠
        Expanded(
          child: _DraftTabContent(
            status: filter.status,
            draftsStream: draftsStream,
            onRefresh: () => ref.invalidate(draftsStreamProvider),
          ),
        ),
      ],
    );
  }
}

/// Draft 탭 컨텐츠 위젯 (기존 DraftsPage에서 복사)
class _DraftTabContent extends ConsumerStatefulWidget {
  final String status;
  final AsyncValue<List<dynamic>> draftsStream;
  final VoidCallback onRefresh;

  const _DraftTabContent({
    required this.status,
    required this.draftsStream,
    required this.onRefresh,
  });

  @override
  ConsumerState<_DraftTabContent> createState() => _DraftTabContentState();
}

class _DraftTabContentState extends ConsumerState<_DraftTabContent> {
  static const _pageSize = 20;
  final _scrollController = ScrollController();
  int _displayLimit = _pageSize;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_DraftTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      setState(() => _displayLimit = _pageSize);
    }
  }

  void _onScroll() {
    if (_isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll - 100;

    if (currentScroll >= threshold) {
      _loadMore();
    }
  }

  void _loadMore() {
    setState(() => _isLoadingMore = true);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _displayLimit += _pageSize;
          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inputMode = ref.watch(fragmentInputModeProvider).value ?? 'inline';
    final isInlineMode = inputMode == 'inline';

    return widget.draftsStream.when(
      data: (allDrafts) {
        final filteredDrafts = widget.status == 'all'
            ? allDrafts
            : allDrafts.where((d) => d.status == widget.status).toList();

        if (filteredDrafts.isEmpty) {
          final theme = ShadTheme.of(context);
          return Center(
            child: Padding(
              padding: EdgeInsets.only(
                left: common.Spacing.xl,
                right: common.Spacing.xl,
                top: common.Spacing.xl,
                bottom: common.Spacing.xl + (isInlineMode ? FragmentInputBar.estimatedHeight : 0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 아이콘 배경
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.muted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      AppIcons.sparkles,
                      size: 40,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: common.Spacing.lg),

                  // 제목
                  Text(
                    widget.status == 'all'
                        ? 'help.draft_empty_title'.tr()
                        : 'draft.empty_filter'.tr(),
                    style: theme.textTheme.h4,
                    textAlign: TextAlign.center,
                  ),

                  if (widget.status == 'all') ...[
                    const SizedBox(height: common.Spacing.sm),

                    // 설명
                    Text(
                      'help.draft_empty_desc'.tr(),
                      style: theme.textTheme.muted,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: common.Spacing.lg),

                    // CTA 힌트
                    Container(
                      padding: const EdgeInsets.all(common.Spacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.muted.withValues(alpha: 0.5),
                        borderRadius:
                            BorderRadius.circular(common.BorderRadii.md),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.info,
                            size: 16,
                            color: theme.colorScheme.mutedForeground,
                          ),
                          const SizedBox(width: common.Spacing.sm),
                          Flexible(
                            child: Text(
                              'help.draft_first_visit'.tr(),
                              style: theme.textTheme.small.copyWith(
                                color: theme.colorScheme.mutedForeground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        final displayedDrafts = filteredDrafts.take(_displayLimit).toList();
        final hasMore = filteredDrafts.length > _displayLimit;

        return RefreshIndicator(
          onRefresh: () async {
            widget.onRefresh();
          },
          child: ListView.separated(
            controller: _scrollController,
            padding: EdgeInsets.only(
              left: common.Spacing.md,
              right: common.Spacing.md,
              top: common.Spacing.md,
              bottom: FragmentInputBar.estimatedHeight + 8, // 입력창 높이 + SafeArea + 추가 여유
            ),
            itemCount: displayedDrafts.length + (hasMore ? 1 : 0),
            separatorBuilder: (context, index) => SizedBox(
              height: common.Spacing.sm + common.Spacing.xs,
            ),
            itemBuilder: (context, index) {
              if (index < displayedDrafts.length) {
                final draft = displayedDrafts[index];
                return DraftCard(draft: draft, onUpdate: widget.onRefresh);
              } else {
                return const Padding(
                  padding: EdgeInsets.all(common.Spacing.md),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        final theme = ShadTheme.of(context);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(common.Spacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  AppIcons.error,
                  size: 64,
                  color: theme.colorScheme.destructive,
                ),
                SizedBox(height: common.Spacing.md),
                Text(
                  'timeline.error_title'.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: common.Spacing.sm),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
