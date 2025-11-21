import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../widgets/subscription_content.dart';

/// 구독 관리 전체 화면 페이지
///
/// 설정에서 구독 메뉴 탭 시 이동
class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('subscription.title'.tr()),
      ),
      body: SafeArea(
        child: SubscriptionContent(
          compact: false,
          onSubscribed: () {
            // 구독 완료 후 뒤로 가기
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
