import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_icons.dart';
import '../../providers/fragments_provider.dart';
import '../widgets/calendar_view.dart';
import '../widgets/filter_bar.dart';
import '../widgets/fragment_input_bar.dart';
import '../widgets/fragment_list.dart';

/// Timeline 메인 화면
///
/// Fragment 리스트 + 하단 고정 입력바
/// Timeline ↔ Calendar 뷰 전환 가능
class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  // 뷰 모드: timeline 또는 calendar
  String _viewMode = 'timeline';

  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == 'timeline' ? 'calendar' : 'timeline';
    });
  }

  @override
  Widget build(BuildContext context) {
    final fragmentsAsync = ref.watch(fragmentsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_viewMode == 'timeline'
            ? 'timeline.title'.tr()
            : 'calendar.title'.tr()),
        actions: [
          // 뷰 토글 버튼
          IconButton(
            icon: Icon(_viewMode == 'timeline'
                ? AppIcons.calendar
                : AppIcons.sparkles),
            tooltip: _viewMode == 'timeline'
                ? 'calendar.switch_to_calendar'.tr()
                : 'calendar.switch_to_timeline'.tr(),
            onPressed: _toggleViewMode,
          ),
          // Drafts
          IconButton(
            icon: Icon(AppIcons.drafts),
            onPressed: () => context.push('/drafts'),
          ),
          // Posts
          IconButton(
            icon: Icon(AppIcons.posts),
            onPressed: () => context.push('/posts'),
          ),
          // Settings
          PopupMenuButton(
            icon: Icon(AppIcons.moreVert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Text('settings.title'.tr()),
              ),
            ],
            onSelected: (value) {
              if (value == 'settings') {
                context.push('/settings');
              }
            },
          ),
        ],
      ),
      body: _viewMode == 'timeline'
          ? Column(
              children: [
                const FilterBar(),
                const Expanded(child: FragmentList()),
              ],
            )
          : fragmentsAsync.when(
              data: (fragments) => CalendarView(allFragments: fragments),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('timeline.error_title'.tr()),
              ),
            ),
      bottomNavigationBar: _viewMode == 'timeline' ? const FragmentInputBar() : null,
    );
  }
}
