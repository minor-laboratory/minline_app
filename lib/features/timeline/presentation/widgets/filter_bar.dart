import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/utils/app_icons.dart';
import '../../providers/fragments_provider.dart';

/// Timeline 필터 바
///
/// 검색, 정렬, 태그 필터 기능 제공 (ShadInput 사용)
class FilterBar extends ConsumerStatefulWidget {
  const FilterBar({super.key});

  @override
  ConsumerState<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends ConsumerState<FilterBar> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterAsync = ref.watch(fragmentFilterProvider);
    final theme = ShadTheme.of(context);

    // AsyncValue에서 값 추출, 로딩/에러 시 기본값 사용 (UI 깜빡임 방지)
    final filter = filterAsync.asData?.value ?? const FragmentFilterState();

    return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: common.Spacing.md,
          vertical: common.Spacing.sm,
        ),
        child: Row(
          children: [
            // 검색 입력 (태그 Pills 포함)
            Expanded(
              child: Focus(
                onKeyEvent: (node, event) {
                  // Backspace로 마지막 태그 삭제
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.backspace &&
                      _searchController.text.isEmpty &&
                      filter.selectedTags.isNotEmpty) {
                    final lastTag = filter.selectedTags.last;
                    ref
                        .read(fragmentFilterProvider.notifier)
                        .removeTag(lastTag);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: ShadInput(
                  controller: _searchController,
                  focusNode: _focusNode,
                  placeholder: filter.selectedTags.isEmpty
                      ? Text('filter.search_placeholder'.tr())
                      : null,
                  onChanged: (value) {
                    ref
                        .read(fragmentFilterProvider.notifier)
                        .setQuery(value);
                  },
                  style: theme.textTheme.bodyMedium,
                  leading: filter.selectedTags.isNotEmpty
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: filter.selectedTags.map((tag) {
                              return Padding(
                                padding: EdgeInsets.only(right: common.Spacing.xs),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: common.Spacing.xs + 2,
                                    vertical: common.Spacing.xs / 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(common.BorderRadii.full),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        tag,
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      SizedBox(width: common.Spacing.xs / 2),
                                      GestureDetector(
                                        onTap: () {
                                          ref
                                              .read(fragmentFilterProvider.notifier)
                                              .removeTag(tag);
                                        },
                                        child: Icon(
                                          AppIcons.close,
                                          size: 12,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      : null,
                  trailing: (filter.query.isNotEmpty || filter.selectedTags.isNotEmpty)
                      ? ShadButton.ghost(
                          width: 24,
                          height: 24,
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(fragmentFilterProvider.notifier)
                                .clearSearch();
                          },
                          child: Icon(
                            AppIcons.close,
                            size: 16,
                            color: theme.colorScheme.mutedForeground,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            SizedBox(width: common.Spacing.sm),

            // 정렬 버튼
            PopupMenuButton<String>(
              icon: Icon(AppIcons.sort, color: theme.colorScheme.mutedForeground),
              tooltip: 'filter.sort'.tr(),
              onSelected: (value) {
                ref.read(fragmentFilterProvider.notifier).setSortBy(value);
              },
              itemBuilder: (context) => [
                _buildSortMenuItem(
                  context,
                  'event',
                  'filter.sort_event'.tr(),
                  filter.sortBy == 'event',
                ),
                _buildSortMenuItem(
                  context,
                  'created',
                  'filter.sort_created'.tr(),
                  filter.sortBy == 'created',
                ),
                _buildSortMenuItem(
                  context,
                  'updated',
                  'filter.sort_updated'.tr(),
                  filter.sortBy == 'updated',
                ),
              ],
            ),

            // 정렬 방향 토글
            ShadIconButton.ghost(
              padding: EdgeInsets.all(common.Spacing.sm),
              icon: Icon(
                filter.sortOrder == 'desc'
                    ? AppIcons.arrowDown
                    : AppIcons.arrowUp,
                size: 20,
                color: theme.colorScheme.mutedForeground,
              ),
              onPressed: () {
                ref.read(fragmentFilterProvider.notifier).toggleSortOrder();
              },
            ),
          ],
        ),
      );
  }

  PopupMenuItem<String> _buildSortMenuItem(
    BuildContext context,
    String value,
    String label,
    bool isSelected,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Text(label),
          if (isSelected) ...[
            const Spacer(),
            Icon(
              AppIcons.checkCircle,
              size: 16,
              color: ShadTheme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }
}
