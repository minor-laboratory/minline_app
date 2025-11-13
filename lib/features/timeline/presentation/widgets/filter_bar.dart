import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/utils/app_icons.dart';
import '../../providers/fragments_provider.dart';

/// Timeline 필터 바
///
/// 검색, 정렬, 태그 필터 기능 제공
class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(fragmentFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 검색 & 정렬
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // 검색 입력
              Expanded(
                child: ShadInput(
                  onChanged: (value) {
                    ref.read(fragmentFilterProvider.notifier).setQuery(value);
                  },
                  placeholder: Text('filter.search_placeholder'.tr()),
                  leading: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(AppIcons.search, size: 16),
                  ),
                  trailing: filter.query.isNotEmpty
                      ? ShadIconButton.ghost(
                          width: 24,
                          height: 24,
                          padding: EdgeInsets.zero,
                          icon: Icon(AppIcons.close, size: 16),
                          onPressed: () {
                            ref.read(fragmentFilterProvider.notifier).setQuery('');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),

              // 정렬 버튼
              PopupMenuButton<String>(
                icon: Icon(AppIcons.sort),
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
                padding: const EdgeInsets.all(8),
                icon: Icon(
                  filter.sortOrder == 'desc'
                      ? AppIcons.arrowDown
                      : AppIcons.arrowUp,
                  size: 20,
                ),
                onPressed: () {
                  ref.read(fragmentFilterProvider.notifier).toggleSortOrder();
                },
              ),
            ],
          ),
        ),

        // 선택된 태그 칩
        if (filter.selectedTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filter.selectedTags.map((tag) {
                return Chip(
                  label: Text(tag),
                  deleteIcon: Icon(AppIcons.close, size: 16),
                  onDeleted: () {
                    ref.read(fragmentFilterProvider.notifier).removeTag(tag);
                  },
                  backgroundColor: colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
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
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }
}
