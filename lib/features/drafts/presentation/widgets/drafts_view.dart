import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/utils/app_icons.dart';
import '../../providers/drafts_provider.dart';
import 'draft_card.dart';

/// Drafts View (body만)
///
/// AI가 생성한 초안 목록을 표시
class DraftsView extends ConsumerStatefulWidget {
  final String analyzeMessage;

  const DraftsView({
    super.key,
    this.analyzeMessage = '',
  });

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
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
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
class _DraftTabContent extends StatefulWidget {
  final String status;
  final AsyncValue<List<dynamic>> draftsStream;
  final VoidCallback onRefresh;

  const _DraftTabContent({
    required this.status,
    required this.draftsStream,
    required this.onRefresh,
  });

  @override
  State<_DraftTabContent> createState() => _DraftTabContentState();
}

class _DraftTabContentState extends State<_DraftTabContent> {
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
    return widget.draftsStream.when(
      data: (allDrafts) {
        final filteredDrafts = widget.status == 'all'
            ? allDrafts
            : allDrafts.where((d) => d.status == widget.status).toList();

        if (filteredDrafts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.sparkles,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.status == 'all'
                        ? 'draft.empty_message'.tr()
                        : 'draft.empty_filter'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (widget.status == 'all') ...[
                    const SizedBox(height: 8),
                    Text(
                      'draft.empty_hint'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
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
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: displayedDrafts.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < displayedDrafts.length) {
                final draft = displayedDrafts[index];
                return DraftCard(
                  draft: draft,
                  onUpdate: widget.onRefresh,
                );
              } else {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                'timeline.error_title'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
