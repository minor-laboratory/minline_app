import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_icons.dart';
import '../../../../models/draft.dart';
import '../../../drafts/providers/drafts_provider.dart';
import '../../providers/fragments_provider.dart';
import 'fragment_card.dart';

/// Fragment 리스트 위젯 (무한 스크롤)
///
/// Timeline 화면의 메인 리스트
class FragmentList extends ConsumerStatefulWidget {
  final VoidCallback? onEnterSearchMode;

  const FragmentList({
    super.key,
    this.onEnterSearchMode,
  });

  @override
  ConsumerState<FragmentList> createState() => _FragmentListState();
}

class _FragmentListState extends ConsumerState<FragmentList> {
  static const int _pageSize = 30; // 웹과 동일
  int _displayLimit = _pageSize;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

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

  void _onScroll() {
    if (_isLoadingMore) return;

    // 하단 100px 이내에 도달하면 더 로드
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // 다음 프레임에서 로드 (UI 업데이트 우선)
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
    final fragmentsAsync = ref.watch(filteredFragmentsProvider);
    final draftsAsync = ref.watch(draftsStreamProvider);

    return fragmentsAsync.when(
      data: (allFragments) {
        if (allFragments.isEmpty) {
          return _buildEmptyState(context);
        }

        // Draft Map 생성 (Fragment remoteID -> Draft)
        final draftMap = <String, Draft>{};
        draftsAsync.whenData((drafts) {
          for (final draft in drafts) {
            for (final fragmentId in draft.fragmentIds) {
              draftMap[fragmentId] = draft;
            }
          }
        });

        // 표시할 fragments (페이지네이션)
        final displayedFragments = allFragments.take(_displayLimit).toList();
        final hasMore = allFragments.length > _displayLimit;

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(
            top: 8,
            bottom: 100, // 하단 입력바 여유 공간
          ),
          itemCount: displayedFragments.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            // 마지막 항목 + 더 많은 항목이 있으면 로딩 인디케이터
            if (index == displayedFragments.length && hasMore) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _isLoadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
                ),
              );
            }

            final fragment = displayedFragments[index];
            final draft = draftMap[fragment.remoteID];
            return FragmentCard(
              fragment: fragment,
              draft: draft,
              onTagClick: (tag) {
                // 태그 필터 토글
                ref.read(fragmentFilterProvider.notifier).toggleTag(tag);
                // 검색 모드로 자동 전환
                widget.onEnterSearchMode?.call();
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.error,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'timeline.error_loading'.tr(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      colorScheme.surfaceContainerHighest,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sparkles 아이콘 (원형 배경)
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppIcons.sparkles,
                        size: 32,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 제목
                    Text(
                      'snap.empty'.tr(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 설명
                    Text(
                      'snap.empty_hint'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 입력 힌트
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.arrowUp,
                            size: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'snap.input_placeholder'.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
