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
    final filteredDraftsStream = ref.watch(filteredDraftsProvider);
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

          // 필터 버튼
          countsStream.when(
            data: (counts) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: 'draft.filter_all'.tr(),
                    count: counts['all'] ?? 0,
                    isSelected: filter.status == 'all',
                    onTap: () => ref
                        .read(draftFilterProvider.notifier)
                        .setStatus('all'),
                  ),
                  _FilterChip(
                    label: 'draft.filter_pending'.tr(),
                    count: counts['pending'] ?? 0,
                    isSelected: filter.status == 'pending',
                    onTap: () => ref
                        .read(draftFilterProvider.notifier)
                        .setStatus('pending'),
                  ),
                  _FilterChip(
                    label: 'draft.filter_accepted'.tr(),
                    count: counts['accepted'] ?? 0,
                    isSelected: filter.status == 'accepted',
                    onTap: () => ref
                        .read(draftFilterProvider.notifier)
                        .setStatus('accepted'),
                  ),
                  _FilterChip(
                    label: 'draft.filter_rejected'.tr(),
                    count: counts['rejected'] ?? 0,
                    isSelected: filter.status == 'rejected',
                    onTap: () => ref
                        .read(draftFilterProvider.notifier)
                        .setStatus('rejected'),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Draft 리스트
          Expanded(
            child: filteredDraftsStream.when(
              data: (drafts) {
                if (drafts.isEmpty) {
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
                            filter.status == 'all'
                                ? 'draft.empty_message'.tr()
                                : 'draft.empty_filter'.tr(),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (filter.status == 'all') ...[
                            const SizedBox(height: 8),
                            Text(
                              'draft.empty_hint'.tr(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(draftsStreamProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: drafts.length,
                    itemBuilder: (context, index) {
                      final draft = drafts[index];
                      return DraftCard(
                        draft: draft,
                        onUpdate: () {
                          ref.invalidate(draftsStreamProvider);
                        },
                      );
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
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 필터 칩 위젯
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      showCheckmark: false,
    );
  }
}
