import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/utils/app_icons.dart';
import '../../../../models/fragment.dart';

/// Fragment 카드 위젯
///
/// Timeline 화면에서 사용하는 개별 Fragment 카드
class FragmentCard extends StatelessWidget {
  final Fragment fragment;

  const FragmentCard({
    super.key,
    required this.fragment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 텍스트 내용
          if (fragment.content.isNotEmpty) ...[
            Text(
              fragment.content,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 이미지
          if (fragment.mediaUrls.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fragment.mediaUrls.map((url) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    width: 128,
                    height: 128,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 128,
                        height: 128,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          AppIcons.image,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // 이벤트 시간
          Row(
            children: [
              Icon(
                _getEventTimeIcon(fragment.eventTimeSource),
                size: 14,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _formatEventTime(context, fragment.eventTime, fragment.eventTimeSource),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          // 태그
          if (fragment.tags.isNotEmpty || fragment.userTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // AI 태그
                ...fragment.tags.map((tag) => _buildAITag(context, tag)),
                // 사용자 태그
                ...fragment.userTags.map((tag) => _buildUserTag(context, tag)),
              ],
            ),
          ],

          // 작성 시간
          const SizedBox(height: 12),
          Text(
            _formatTimestamp(context, fragment.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 이벤트 시간 아이콘
  IconData _getEventTimeIcon(String source) {
    if (source.startsWith('ai')) {
      return AppIcons.sparkles; // AI 추론 시간
    } else if (source.startsWith('user')) {
      return AppIcons.calendar; // 사용자 설정 시간
    } else {
      return AppIcons.clock; // 자동 (작성 시간)
    }
  }

  /// 이벤트 시간 포맷
  String _formatEventTime(BuildContext context, DateTime date, String source) {
    final includeTime = source.contains('time') || source == 'auto';
    final now = DateTime.now();
    final diff = now.difference(date);

    // 상대 시간 (time variant만, 7일 이내)
    if (includeTime) {
      if (diff.inMinutes < 1) return 'time.just_now'.tr();
      if (diff.inMinutes < 60) return 'time.minutes_ago'.tr(args: [diff.inMinutes.toString()]);
      if (diff.inHours < 24) return 'time.hours_ago'.tr(args: [diff.inHours.toString()]);
      if (diff.inDays < 7) return 'time.days_ago'.tr(args: [diff.inDays.toString()]);
    }

    // 절대 시간
    final locale = Localizations.localeOf(context).languageCode;
    final format = includeTime ? 'time.datetime_format'.tr() : 'time.date_format'.tr();
    return intl.DateFormat(format, locale).format(date);
  }

  /// 작성 시간 포맷 (항상 상대 시간)
  String _formatTimestamp(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'time.just_now'.tr();
    if (diff.inMinutes < 60) return 'time.minutes_ago'.tr(args: [diff.inMinutes.toString()]);
    if (diff.inHours < 24) return 'time.hours_ago'.tr(args: [diff.inHours.toString()]);
    if (diff.inDays < 7) return 'time.days_ago'.tr(args: [diff.inDays.toString()]);

    final locale = Localizations.localeOf(context).languageCode;
    return intl.DateFormat('time.date_format'.tr(), locale).format(date);
  }

  /// AI 태그 위젯
  Widget _buildAITag(BuildContext context, String tag) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.sparkles, size: 12, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            tag,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 사용자 태그 위젯
  Widget _buildUserTag(BuildContext context, String tag) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
