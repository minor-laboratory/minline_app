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
      nameKey: 'template.product_review',
      descKey: 'template.product_review_desc',
    ),
    PostTemplate(
      id: 'timeline',
      icon: AppIcons.calendar,
      nameKey: 'template.timeline',
      descKey: 'template.timeline_desc',
    ),
    PostTemplate(
      id: 'essay',
      icon: AppIcons.edit,
      nameKey: 'template.essay',
      descKey: 'template.essay_desc',
    ),
    PostTemplate(
      id: 'travel',
      icon: AppIcons.plane,
      nameKey: 'template.travel',
      descKey: 'template.travel_desc',
    ),
    PostTemplate(
      id: 'project',
      icon: AppIcons.rocket,
      nameKey: 'template.project',
      descKey: 'template.project_desc',
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
