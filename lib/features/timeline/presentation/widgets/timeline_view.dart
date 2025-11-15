import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/fragments_provider.dart';
import 'calendar_view.dart';
import 'fragment_input_bar.dart';
import 'fragment_list.dart';

/// Timeline View (body만)
///
/// Fragment 리스트 + 하단 고정 입력바
class TimelineView extends ConsumerStatefulWidget {
  final String viewMode; // 'timeline' | 'calendar'

  const TimelineView({
    super.key,
    this.viewMode = 'timeline',
  });

  @override
  ConsumerState<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends ConsumerState<TimelineView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final fragmentsAsync = ref.watch(fragmentsStreamProvider);

    return widget.viewMode == 'timeline'
        ? const Column(
            children: [
              Expanded(child: FragmentList()),
              FragmentInputBar(),
            ],
          )
        : fragmentsAsync.when(
            data: (fragments) => CalendarView(allFragments: fragments),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('timeline.error_title'.tr())),
          );
  }
}
