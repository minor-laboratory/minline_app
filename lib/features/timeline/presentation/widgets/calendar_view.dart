import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/utils/app_icons.dart';
import '../../../../models/fragment.dart';
import 'fragment_card.dart';

/// 캘린더 뷰 위젯
///
/// 월간 캘린더로 Fragment를 날짜별로 탐색
class CalendarView extends ConsumerStatefulWidget {
  final List<Fragment> allFragments;

  const CalendarView({
    required this.allFragments,
    super.key,
  });

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
    final startWeekday = firstDay.weekday % 7; // DateTime uses 1-7, convert to 0-6

    // 첫 주의 빈 칸 채우기 (이전 월 날짜)
    final previousMonthDays = <DateTime>[];
    for (var i = 0; i < startWeekday; i++) {
      previousMonthDays.add(firstDay.subtract(Duration(days: startWeekday - i)));
    }

    // 현재 월의 모든 날짜
    final currentMonthDays = <DateTime>[];
    for (var i = 0; i < lastDay.day; i++) {
      currentMonthDays.add(DateTime(_currentMonth.year, _currentMonth.month, i + 1));
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
    return date.year == now.year && date.month == now.month && date.day == now.day;
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

  /// Fragment 개수 점 표시
  String _getFragmentDots(int count) {
    if (count == 1) return '•';
    if (count == 2) return '••';
    if (count == 3) return '•••';
    return '•••+';
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
    final colorScheme = Theme.of(context).colorScheme;
    final fragmentCounts = _getFragmentCountByDate();
    final selectedFragments = _getFragmentsForSelectedDate();

    return Column(
      children: [
        // 월 선택 헤더
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShadIconButton.ghost(
                padding: const EdgeInsets.all(8),
                icon: Icon(AppIcons.chevronLeft, size: 20),
                onPressed: _previousMonth,
              ),
              Text(
                DateFormat('MMMM yyyy').format(_currentMonth),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShadButton.ghost(
                    onPressed: _goToToday,
                    child: Text('calendar.today'.tr()),
                  ),
                  ShadIconButton.ghost(
                    padding: const EdgeInsets.all(8),
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              'calendar.weekday_sun',
              'calendar.weekday_mon',
              'calendar.weekday_tue',
              'calendar.weekday_wed',
              'calendar.weekday_thu',
              'calendar.weekday_fri',
              'calendar.weekday_sat',
            ]
                .map((key) => Expanded(
                      child: Center(
                        child: Text(
                          key.tr(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),

        const SizedBox(height: 8),

        // 캘린더 그리드
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
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
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : null,
                    border: !isSelected && isToday
                        ? Border.all(color: colorScheme.primary, width: 2)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : !isSameMonth
                                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                                  : colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : null,
                        ),
                      ),
                      if (fragmentCount > 0)
                        Text(
                          _getFragmentDots(fragmentCount),
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.primary,
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: const ShadSeparator.horizontal(),
        ),

        // 선택된 날짜의 Fragment 리스트
        Expanded(
          child: selectedFragments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'calendar.no_fragments'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: selectedFragments.length,
                  itemBuilder: (context, index) {
                    return FragmentCard(
                      fragment: selectedFragments[index],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
