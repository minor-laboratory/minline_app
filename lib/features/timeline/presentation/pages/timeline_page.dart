import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/app_icons.dart';
import '../widgets/fragment_input_bar.dart';
import '../widgets/fragment_list.dart';

/// Timeline 메인 화면
///
/// Fragment 리스트 + 하단 고정 입력바
class TimelinePage extends StatelessWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('timeline.title'.tr()),
        actions: [
          // Drafts (나중에 구현)
          IconButton(
            icon: Icon(AppIcons.drafts),
            onPressed: () {
              // TODO: Navigate to Drafts
            },
          ),
          // Posts (나중에 구현)
          IconButton(
            icon: Icon(AppIcons.posts),
            onPressed: () {
              // TODO: Navigate to Posts
            },
          ),
          // Settings (나중에 구현)
          PopupMenuButton(
            icon: Icon(AppIcons.moreVert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Text('settings.title'.tr()),
              ),
            ],
            onSelected: (value) {
              // TODO: Navigate to Settings
            },
          ),
        ],
      ),
      body: const FragmentList(),
      bottomNavigationBar: const FragmentInputBar(),
    );
  }
}
