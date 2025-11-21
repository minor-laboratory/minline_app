import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/standard_bottom_sheet.dart';
import 'subscription_content.dart';

/// 구독 BottomSheet
///
/// 무료 한도 초과 시 표시
class SubscriptionSheet {
  SubscriptionSheet._();

  /// 구독 시트 표시
  ///
  /// 구독 완료 시 true 반환
  static Future<bool?> show(BuildContext context) async {
    bool subscribed = false;

    await StandardBottomSheet.show(
      context: context,
      title: 'premium.title'.tr(),
      content: SubscriptionContent(
        compact: true,
        onSubscribed: () {
          subscribed = true;
          Navigator.of(context).pop();
        },
      ),
      isDraggable: true,
      isDismissible: true,
    );

    return subscribed ? true : null;
  }
}
