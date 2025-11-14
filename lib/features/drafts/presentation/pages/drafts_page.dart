import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/app_icons.dart';
import '../../../../core/utils/logger.dart';
import '../../providers/drafts_provider.dart';
import '../widgets/draft_card.dart';

/// Drafts 화면
///
/// AI가 생성한 초안 목록을 표시
class DraftsPage extends ConsumerStatefulWidget {
  const DraftsPage({super.key});

  @override
  ConsumerState<DraftsPage> createState() => _DraftsPageState();
}

class _DraftsPageState extends ConsumerState<DraftsPage> {
  bool _isAnalyzing = false;
  String _analyzeMessage = '';

  /// AI 분석 실행 (analyze-fragments Edge Function 호출)
  Future<void> _handleAnalyzeNow() async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _analyzeMessage = '';
    });

    try {
      final supabase = Supabase.instance.client;

      // 세션 확인
      final session = supabase.auth.currentSession;
      if (session == null) {
        setState(() {
          _analyzeMessage = 'auth.login_required'.tr();
        });
        return;
      }

      // analyze-fragments Edge Function 호출
      final response = await supabase.functions.invoke('analyze-fragments');

      if (response.status != 200) {
        logger.e('❌ analyze-fragments 실패: ${response.data}');
        setState(() {
          _analyzeMessage = 'draft.analyze_failed'.tr();
        });
        return;
      }

      final result = response.data as Map<String, dynamic>;
      logger.i('✅ Draft 분석 완료: $result');

      // 성공 메시지 표시
      final draftsCreated = result['drafts_created'] as int? ?? 0;
      setState(() {
        if (draftsCreated > 0) {
          _analyzeMessage =
              'draft.analyze_success'.tr(namedArgs: {'count': draftsCreated.toString()});
        } else {
          _analyzeMessage = 'draft.analyze_no_results'.tr();
        }
      });

      // Provider 무효화로 자동 갱신
      ref.invalidate(draftsStreamProvider);
    } catch (error) {
      logger.e('❌ Draft 분석 오류:', error);
      setState(() {
        _analyzeMessage = 'draft.analyze_failed'.tr();
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(draftFilterProvider);
    final draftsStream = ref.watch(draftsStreamProvider);
    final countsStream = ref.watch(draftCountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('drafts.title'.tr()),
        actions: [
          // AI 분석 버튼
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ShadButton.ghost(
              onPressed: _isAnalyzing ? null : _handleAnalyzeNow,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isAnalyzing)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(AppIcons.sparkles, size: 16),
                  const SizedBox(width: 8),
                  Text(_isAnalyzing
                      ? 'draft.analyzing'.tr()
                      : 'draft.analyze_now'.tr()),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 분석 결과 메시지
          if (_analyzeMessage.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _analyzeMessage,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),

          // Shadcn Tabs
          Expanded(
            child: countsStream.when(
              data: (counts) => ShadTabs<String>(
                value: filter.status,
                onChanged: (value) {
                  ref.read(draftFilterProvider.notifier).setStatus(value);
                },
                tabs: [
                  ShadTab(
                    value: 'all',
                    content: _DraftTabContent(
                      status: 'all',
                      draftsStream: draftsStream,
                      onRefresh: () => ref.invalidate(draftsStreamProvider),
                    ),
                    child: Text('${'draft.filter_all'.tr()} (${counts['all'] ?? 0})'),
                  ),
                  ShadTab(
                    value: 'pending',
                    content: _DraftTabContent(
                      status: 'pending',
                      draftsStream: draftsStream,
                      onRefresh: () => ref.invalidate(draftsStreamProvider),
                    ),
                    child: Text('${'draft.filter_pending'.tr()} (${counts['pending'] ?? 0})'),
                  ),
                  ShadTab(
                    value: 'accepted',
                    content: _DraftTabContent(
                      status: 'accepted',
                      draftsStream: draftsStream,
                      onRefresh: () => ref.invalidate(draftsStreamProvider),
                    ),
                    child: Text('${'draft.filter_accepted'.tr()} (${counts['accepted'] ?? 0})'),
                  ),
                  ShadTab(
                    value: 'rejected',
                    content: _DraftTabContent(
                      status: 'rejected',
                      draftsStream: draftsStream,
                      onRefresh: () => ref.invalidate(draftsStreamProvider),
                    ),
                    child: Text('${'draft.filter_rejected'.tr()} (${counts['rejected'] ?? 0})'),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Error loading counts')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draft 탭 컨텐츠 위젯
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
    // 필터 변경 시 페이지네이션 리셋
    if (oldWidget.status != widget.status) {
      setState(() => _displayLimit = _pageSize);
    }
  }

  void _onScroll() {
    if (_isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll - 100; // 100px 전에 미리 로드

    if (currentScroll >= threshold) {
      _loadMore();
    }
  }

  void _loadMore() {
    setState(() => _isLoadingMore = true);

    // 100ms 디바운스
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
        // 필터링
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

        // 무한 스크롤을 위한 슬라이싱
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
                // 로딩 인디케이터
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
