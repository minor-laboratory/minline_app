import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Posts 화면 (Placeholder)
///
/// Phase 2.4에서 구현 예정
class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('posts.title'.tr()),
      ),
      body: Center(
        child: Text(
          'posts.coming_soon'.tr(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
