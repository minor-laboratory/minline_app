# shadcn_ui 컴포넌트 사용 가이드

> **작성일**: 2025-11-13
> **프로젝트**: MiniLine App (Flutter)
> **참조**: [Flutter Shadcn UI 공식 문서](https://flutter-shadcn-ui.mariuti.com/)

**언제 읽어야 하는가:**
- shadcn_ui 컴포넌트 사용 전 (필수)
- Material 위젯을 shadcn_ui로 변환할 때
- Dialog/Sheet/Button/Input 구현 시

---

## 📐 기본 원칙

### shadcn_ui가 기본
- **모든 UI 컴포넌트**: shadcn_ui 사용
- **Material 기본 위젯**: Scaffold, AppBar, Column 등만 사용
- **일관성**: 웹 버전(shadcn-svelte)과 동일한 디자인

### Import
```dart
import 'package:shadcn_ui/shadcn_ui.dart';

// Material 기본 위젯 필요 시
import 'package:flutter/material.dart';
```

---

## 🔘 ShadButton

### 기본 사용
```dart
// Primary (기본)
ShadButton(
  onPressed: () {},
  child: Text('common.save'.tr()),
)

// Outline
ShadButton.outline(
  onPressed: () {},
  child: Text('common.cancel'.tr()),
)

// Ghost
ShadButton.ghost(
  onPressed: () {},
  child: Text('common.skip'.tr()),
)

// Destructive
ShadButton.destructive(
  onPressed: () {},
  child: Text('common.delete'.tr()),
)

// Secondary
ShadButton.secondary(
  onPressed: () {},
  child: Text('common.more'.tr()),
)

// Link
ShadButton.link(
  onPressed: () {},
  child: Text('common.learn_more'.tr()),
)
```

### 아이콘 포함 버튼
```dart
// leading 파라미터 사용
ShadButton(
  onPressed: () {},
  leading: Icon(AppIcons.save, size: 16),
  child: Text('common.save'.tr()),
)

// 로딩 상태
ShadButton(
  onPressed: isLoading ? null : _save,
  child: isLoading
    ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text('common.saving'.tr()),
        ],
      )
    : Text('common.save'.tr()),
)
```

### 아이콘 전용 버튼
```dart
// ❌ 잘못: ShadButton.ghost + child
ShadButton.ghost(
  padding: const EdgeInsets.all(8),
  child: Icon(AppIcons.close),
)

// ✅ 올바름: ShadIconButton 사용
ShadIconButton.ghost(
  icon: Icon(AppIcons.close),
  onPressed: () {},
)

// 다른 variant
ShadIconButton(icon: Icon(AppIcons.add))           // Primary
ShadIconButton.secondary(icon: Icon(AppIcons.edit))
ShadIconButton.outline(icon: Icon(AppIcons.share))
ShadIconButton.destructive(icon: Icon(AppIcons.delete))
```

---

## 📝 ShadInput

### 기본 입력
```dart
ShadInput(
  controller: controller,
  placeholder: Text('snap.input_placeholder'.tr()),
  onChanged: (value) {
    // 처리
  },
)

// leading/trailing 아이콘
ShadInput(
  placeholder: Text('filter.search_placeholder'.tr()),
  leading: Padding(
    padding: const EdgeInsets.all(4.0),
    child: Icon(AppIcons.search, size: 16),
  ),
)
```

### Trailing 버튼 (중요!)

**⚠️ 필수**: trailing 버튼은 **반드시 크기 고정**

```dart
// ✅ 올바름: 크기 고정
ShadInput(
  controller: controller,
  trailing: value.text.isNotEmpty
    ? ShadButton.ghost(
        width: 24,         // 필수
        height: 24,        // 필수
        padding: EdgeInsets.zero,
        onPressed: () => controller.clear(),
        child: Icon(AppIcons.close, size: 16),
      )
    : null,
)

// ❌ 잘못: 크기 미지정 → 입력창 높이 변경됨!
ShadInput(
  trailing: ShadButton.ghost(
    onPressed: () {},
    child: Icon(AppIcons.close),
  ),
)
```

### Textarea
```dart
ShadTextarea(
  controller: controller,
  placeholder: Text('snap.input_placeholder'.tr()),
  minLines: 2,
  maxLines: 5,
  maxLength: 300,
)
```

---

## 💬 ShadDialog

### 기본 다이얼로그

**⚠️ 중요**: MiniLine 앱에서는 **Dialog 사용 제한적**
- 확인/삭제 등 **단순 확인**만 Dialog 사용
- **텍스트 입력 필요 시**: 페이지로 구현 (Dialog 사용 금지)
- **설정 선택 등**: Sheet 사용

```dart
// ✅ 허용: 단순 확인 다이얼로그
final confirmed = await showShadDialog<bool>(
  context: context,
  builder: (context) => ShadDialog(
    title: Text('draft.delete_title'.tr()),
    description: Text('draft.delete_confirm'.tr()),
    actions: [
      ShadButton.outline(
        onPressed: () => Navigator.of(context).pop(false),
        child: Text('common.cancel'.tr()),
      ),
      ShadButton.destructive(
        onPressed: () => Navigator.of(context).pop(true),
        child: Text('common.delete'.tr()),
      ),
    ],
  ),
);

// ❌ 금지: 텍스트 입력 받는 Dialog
showShadDialog(
  context: context,
  builder: (context) => ShadDialog(
    child: TextField(), // 금지!
  ),
);

// ✅ 대신: 페이지로 구현
context.push('/edit-name');
```

### Alert Dialog
```dart
ShadDialog.alert(
  title: Text('warning.title'.tr()),
  description: Text('warning.message'.tr()),
  actions: [
    ShadButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text('common.ok'.tr()),
    ),
  ],
)
```

---

## 📋 ShadSheet

### Bottom Sheet 사용

**MiniLine 앱 규칙**:
- **설정 선택**: Sheet 사용
- **리스트 선택**: Sheet 사용
- **텍스트 입력**: 페이지 사용 (Sheet 금지)

```dart
// ✅ 올바름: 설정 선택
showShadSheet(
  context: context,
  side: ShadSheetSide.bottom,
  builder: (context) => ShadSheet(
    title: Text('settings.theme'.tr()),
    description: Text('settings.theme_desc'.tr()),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text('theme.light'.tr()),
          onTap: () {
            _setTheme('light');
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: Text('theme.dark'.tr()),
          onTap: () {
            _setTheme('dark');
            Navigator.pop(context);
          },
        ),
      ],
    ),
  ),
);

// ❌ 금지: 텍스트 입력 Sheet
showShadSheet(
  context: context,
  builder: (context) => ShadSheet(
    child: TextField(), // 금지!
  ),
);
```

### Side Sheet
```dart
// Right sheet (태블릿용)
showShadSheet(
  context: context,
  side: ShadSheetSide.right,
  builder: (context) => ShadSheet(
    title: Text('settings.title'.tr()),
    child: SettingsContent(),
    constraints: BoxConstraints(maxWidth: 512),
  ),
);
```

---

## 📇 ShadCard

### 기본 카드
```dart
ShadCard(
  title: Text('Title'),
  description: Text('Description'),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text('Content'),
  ),
)

// Footer 포함
ShadCard(
  title: Text('Title'),
  child: Content(),
  footer: Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      ShadButton.outline(
        onPressed: () {},
        child: Text('common.cancel'.tr()),
      ),
      const SizedBox(width: 8),
      ShadButton(
        onPressed: () {},
        child: Text('common.save'.tr()),
      ),
    ],
  ),
)
```

---

## 🏷️ ShadBadge

### Badge 사용
```dart
// Primary
ShadBadge(
  child: Text('New'),
)

// Secondary
ShadBadge.secondary(
  child: Text('Beta'),
)

// Destructive
ShadBadge.destructive(
  child: Text('Error'),
)

// Outline
ShadBadge.outline(
  child: Text('Draft'),
)
```

---

## ➖ ShadSeparator

### Separator 사용
```dart
// Horizontal (기본)
const ShadSeparator.horizontal()

// Vertical
const ShadSeparator.vertical()

// 커스텀 스타일
const ShadSeparator.horizontal(
  thickness: 2,
  margin: EdgeInsets.symmetric(vertical: 16),
)
```

---

## 📏 일반 규칙

### 1. 크기 단위
- Flutter: dp (density-independent pixels)
- 웹과 1:1 매핑 (px → dp)

### 2. 색상
```dart
// ✅ 테마 색상 사용
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.surface

// ❌ 하드코딩 금지
Colors.blue
Color(0xFF2563EB)
```

### 3. 아이콘
```dart
// ✅ AppIcons 사용
Icon(AppIcons.add)
Icon(AppIcons.close)

// ❌ Material Icons 직접 사용 금지
Icon(Icons.add)
Icon(Icons.close)
```

### 4. 다국어
```dart
// ✅ .tr() 사용
Text('common.save'.tr())
Text('draft.delete_title'.tr())

// ❌ 하드코딩 금지
Text('Save')
Text('Delete')
```

---

## ⚠️ 자주 하는 실수

### 1. trailing 버튼 크기 미지정
```dart
// ❌ 잘못
ShadInput(
  trailing: ShadButton.ghost(
    child: Icon(AppIcons.close),
  ),
)

// ✅ 올바름
ShadInput(
  trailing: ShadButton.ghost(
    width: 24,
    height: 24,
    padding: EdgeInsets.zero,
    child: Icon(AppIcons.close, size: 16),
  ),
)
```

### 2. 아이콘 버튼에 ShadButton 사용
```dart
// ❌ 잘못
ShadButton.ghost(
  child: Icon(AppIcons.close),
)

// ✅ 올바름
ShadIconButton.ghost(
  icon: Icon(AppIcons.close),
)
```

### 3. Dialog에 텍스트 입력
```dart
// ❌ 잘못
showShadDialog(
  context: context,
  builder: (context) => ShadDialog(
    child: TextField(),
  ),
)

// ✅ 올바름: 페이지로 구현
context.push('/edit-name');
```

### 4. Separator에 const 오용
```dart
// ❌ 잘못
const ShadSeparator()  // unnamed constructor 없음

// ✅ 올바름
const ShadSeparator.horizontal()
```

---

## 📋 체크리스트

**컴포넌트 사용 전 확인:**
- [ ] shadcn_ui import 추가
- [ ] Material 위젯 대신 shadcn_ui 사용
- [ ] trailing 버튼 크기 고정
- [ ] 아이콘 전용 버튼은 ShadIconButton 사용
- [ ] Dialog는 단순 확인만 사용
- [ ] 텍스트 입력은 페이지로 구현
- [ ] 테마 색상 사용 (하드코딩 금지)
- [ ] AppIcons 사용 (Material Icons 금지)
- [ ] 다국어 키 사용 (.tr())

---

## 🔗 참고 문서

- [Flutter Shadcn UI 공식 문서](https://flutter-shadcn-ui.mariuti.com/)
- [/docs/common/GUIDE_STYLE_COMPONENTS.md](/docs/common/GUIDE_STYLE_COMPONENTS.md)
- [docs/MIGRATION_SHADCN.md](MIGRATION_SHADCN.md)
- [docs/COMPONENT_SPECS.md](COMPONENT_SPECS.md)
