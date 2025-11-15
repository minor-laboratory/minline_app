import 'package:flutter/material.dart';

import '../utils/app_icons.dart';

// Post 템플릿 정의
//
// 웹 버전과 동일한 구조
// 참조: miniline/src/lib/templates/index.ts

class PostTemplate {
  final String id;
  final IconData icon;
  final String nameKey;
  final String descKey;

  const PostTemplate({
    required this.id,
    required this.icon,
    required this.nameKey,
    required this.descKey,
  });
}

class PostTemplates {
  static const List<PostTemplate> all = [
    PostTemplate(
      id: 'product_review',
      icon: AppIcons.package,
      nameKey: 'post.template_product_review',
      descKey: 'post.template_product_review_desc',
    ),
    PostTemplate(
      id: 'timeline',
      icon: AppIcons.calendar,
      nameKey: 'post.template_timeline',
      descKey: 'post.template_timeline_desc',
    ),
    PostTemplate(
      id: 'essay',
      icon: AppIcons.edit,
      nameKey: 'post.template_essay',
      descKey: 'post.template_essay_desc',
    ),
    PostTemplate(
      id: 'travel',
      icon: AppIcons.plane,
      nameKey: 'post.template_travel',
      descKey: 'post.template_travel_desc',
    ),
    PostTemplate(
      id: 'project',
      icon: AppIcons.rocket,
      nameKey: 'post.template_project',
      descKey: 'post.template_project_desc',
    ),
  ];

  static PostTemplate? getById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
}
