import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final filter = ref.watch(fragmentFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                style: const TextStyle(fontSize: 14),
                leading: filter.selectedTags.isNotEmpty
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: filter.selectedTags.map((tag) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    GestureDetector(
                                      onTap: () {
                                        ref
                                            .read(fragmentFilterProvider.notifier)
                                            .removeTag(tag);
                                      },
                                      child: Icon(
                                        AppIcons.close,
                                        size: 12,
                                        color: colorScheme.primary,
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
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 정렬 버튼
          PopupMenuButton<String>(
            icon: Icon(AppIcons.sort, color: colorScheme.onSurfaceVariant),
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
              color: colorScheme.onSurfaceVariant,
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
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }
}
