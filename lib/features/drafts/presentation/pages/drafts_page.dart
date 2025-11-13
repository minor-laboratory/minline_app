import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Drafts 화면 (Placeholder)
///
/// Phase 2.3에서 구현 예정
class DraftsPage extends StatelessWidget {
  const DraftsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('drafts.title'.tr()),
      ),
      body: Center(
        child: Text(
          'drafts.coming_soon'.tr(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
