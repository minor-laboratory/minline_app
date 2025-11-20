import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/utils/app_icons.dart';
import '../../../../models/fragment.dart';
import 'fragment_card.dart';
import 'fragment_input_bar.dart';

/// 캘린더 뷰 위젯
///
/// 월간 캘린더로 Fragment를 날짜별로 탐색
class CalendarView extends ConsumerStatefulWidget {
  final List<Fragment> allFragments;

  const CalendarView({required this.allFragments, super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  /// 해당 월의 캘린더 날짜 목록 생성 (6주)
  List<DateTime> _generateCalendarDays() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    // 첫 번째 날의 요일 (0: Sunday, 6: Saturday)
    final startWeekday =
        firstDay.weekday % 7; // DateTime uses 1-7, convert to 0-6

    // 첫 주의 빈 칸 채우기 (이전 월 날짜)
    final previousMonthDays = <DateTime>[];
    for (var i = 0; i < startWeekday; i++) {
      previousMonthDays.add(
        firstDay.subtract(Duration(days: startWeekday - i)),
      );
    }

    // 현재 월의 모든 날짜
    final currentMonthDays = <DateTime>[];
    for (var i = 0; i < lastDay.day; i++) {
      currentMonthDays.add(
        DateTime(_currentMonth.year, _currentMonth.month, i + 1),
      );
    }

    // 마지막 주의 빈 칸 채우기 (다음 월 날짜)
    final totalDays = previousMonthDays.length + currentMonthDays.length;
    final remainingDays = (7 - (totalDays % 7)) % 7;
    final nextMonthDays = <DateTime>[];
    for (var i = 0; i < remainingDays; i++) {
      nextMonthDays.add(lastDay.add(Duration(days: i + 1)));
    }

    return [...previousMonthDays, ...currentMonthDays, ...nextMonthDays];
  }

  /// 날짜별 Fragment 개수 계산
  Map<String, int> _getFragmentCountByDate() {
    final counts = <String, int>{};

    for (final fragment in widget.allFragments) {
      final dateKey = _formatDateKey(fragment.eventTime);
      counts[dateKey] = (counts[dateKey] ?? 0) + 1;
    }

    return counts;
  }

  /// 선택된 날짜의 Fragment 목록
  List<Fragment> _getFragmentsForSelectedDate() {
    final selectedKey = _formatDateKey(_selectedDate);

    return widget.allFragments
        .where((f) => _formatDateKey(f.eventTime) == selectedKey)
        .toList()
      ..sort((a, b) => b.eventTime.compareTo(a.eventTime));
  }

  /// 날짜를 YYYY-MM-DD 형식으로 포맷
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 오늘 날짜인지 확인
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// 선택된 날짜인지 확인
  bool _isSelected(DateTime date) {
    return date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
  }

  /// 현재 월의 날짜인지 확인
  bool _isSameMonth(DateTime date) {
    return date.year == _currentMonth.year && date.month == _currentMonth.month;
  }

  /// Fragment 개수 아이콘 위젯 생성
  Widget _buildFragmentCountIndicator(int count, bool isSelected, ShadThemeData theme) {
    final color = isSelected
        ? theme.colorScheme.primaryForeground
        : theme.colorScheme.primary;

    // 1-3개: 점 개수만큼 표시
    if (count <= 3) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          count,
          (index) => Padding(
            padding: EdgeInsets.only(left: index > 0 ? 2 : 0),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }

    // 4개 이상: ••• + Plus 아이콘
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(
          3,
          (index) => Padding(
            padding: EdgeInsets.only(left: index > 0 ? 2 : 0),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        SizedBox(width: 2),
        Icon(AppIcons.add, size: 6, color: color),
      ],
    );
  }

  /// 이전 월로 이동
  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  /// 다음 월로 이동
  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  /// 오늘로 이동
  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  /// 날짜 클릭 처리
  void _onDateClick(DateTime date) {
    if (!_isSameMonth(date)) return; // 다른 월 날짜는 클릭 불가

    setState(() {
      _selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final fragmentCounts = _getFragmentCountByDate();
    final selectedFragments = _getFragmentsForSelectedDate();

    return SingleChildScrollView(
      child: Column(
        children: [
        // 월 선택 헤더
        Padding(
          padding: const EdgeInsets.all(common.Spacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShadIconButton.ghost(
                padding: const EdgeInsets.all(common.Spacing.sm),
                icon: Icon(AppIcons.chevronLeft, size: 20),
                onPressed: _previousMonth,
              ),
              Text(
                DateFormat('MMMM yyyy').format(_currentMonth),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShadButton.ghost(
                    onPressed: _goToToday,
                    child: Text('calendar.today'.tr()),
                  ),
                  ShadIconButton.ghost(
                    padding: const EdgeInsets.all(common.Spacing.sm),
                    icon: Icon(AppIcons.chevronRight, size: 20),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ],
          ),
        ),

        // 요일 헤더
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: common.Spacing.md),
          child: Row(
            children:
                [
                      'calendar.weekday_sun',
                      'calendar.weekday_mon',
                      'calendar.weekday_tue',
                      'calendar.weekday_wed',
                      'calendar.weekday_thu',
                      'calendar.weekday_fri',
                      'calendar.weekday_sat',
                    ]
                    .map(
                      (key) => Expanded(
                        child: Center(
                          child: Text(
                            key.tr(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: theme.colorScheme.mutedForeground,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),

        SizedBox(height: common.Spacing.sm),

        // 캘린더 그리드
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: common.Spacing.md),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: common.Spacing.xs,
              mainAxisSpacing: common.Spacing.xs,
            ),
            itemCount: _generateCalendarDays().length,
            itemBuilder: (context, index) {
              final date = _generateCalendarDays()[index];
              final dateKey = _formatDateKey(date);
              final fragmentCount = fragmentCounts[dateKey] ?? 0;
              final isSelected = _isSelected(date);
              final isToday = _isToday(date);
              final isSameMonth = _isSameMonth(date);

              return InkWell(
                onTap: () => _onDateClick(date),
                borderRadius: BorderRadius.circular(common.BorderRadii.md),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary : null,
                    border: !isSelected && isToday
                        ? Border.all(color: theme.colorScheme.primary, width: 2)
                        : null,
                    borderRadius: BorderRadius.circular(common.BorderRadii.md),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.primaryForeground
                              : !isSameMonth
                              ? theme.colorScheme.mutedForeground.withValues(
                                  alpha: 0.3,
                                )
                              : theme.colorScheme.foreground,
                          fontWeight: isSelected ? FontWeight.w600 : null,
                        ),
                      ),
                      if (fragmentCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: _buildFragmentCountIndicator(
                            fragmentCount,
                            isSelected,
                            theme,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: common.Spacing.md),
          child: const ShadSeparator.horizontal(),
        ),

        // 선택된 날짜의 Fragment 리스트
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: common.Spacing.md),
          child: selectedFragments.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(common.Spacing.lg),
                  child: Text(
                    'calendar.no_fragments'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < selectedFragments.length; i++) ...[
                      FragmentCard(fragment: selectedFragments[i]),
                      if (i < selectedFragments.length - 1)
                        SizedBox(height: common.Spacing.sm + common.Spacing.xs),
                    ],
                  ],
                ),
        ),
        // 하단 여백 (입력창 높이 + SafeArea + 추가 여유)
        SizedBox(height: FragmentInputBar.estimatedHeight + 8),
      ],
      ),
    );
  }
}
