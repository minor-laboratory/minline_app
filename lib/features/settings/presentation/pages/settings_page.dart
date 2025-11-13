import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Settings 화면 (Placeholder)
///
/// 나중에 구현 예정
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings.title'.tr()),
      ),
      body: Center(
        child: Text(
          'settings.coming_soon'.tr(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
