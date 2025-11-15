# shadcn_ui 마이그레이션 가이드

> **현재 상태**: Material UI 중심 + shadcn_ui 선택적 사용 (향후 점진적 마이그레이션 계획)

**언제 읽어야 하는가:**
- 웹과 동일한 UI가 필요할 때 (선택)
- shadcn_ui 컴포넌트 사용 시 참조
- Material 위젯을 shadcn_ui로 교체할 때

## 📊 현재 상태 (2025년 기준)

- **Shadcn Theme**: 100% 적용 완료 (모든 파일에서 `ShadTheme.of(context)` 사용)
- **Material Design → Shadcn 색상 전환**: 완료
  - `colorScheme.onSurfaceVariant` → `theme.colorScheme.mutedForeground`
  - `colorScheme.surfaceVariant` → `theme.colorScheme.muted`
  - `colorScheme.outline` → `theme.colorScheme.border`
- **혼용 가능**: ShadApp.custom으로 Material 위젯 + Shadcn Theme 모두 사용
- **기본 원칙**: Material 위젯 사용, Shadcn Theme 시스템 사용

## 📐 웹↔앱 컴포넌트 매핑

| 웹 (shadcn-svelte) | 앱 (shadcn_ui) | 문서 |
|---|---|---|
| Button | ShadButton | [docs](https://flutter-shadcn-ui.mariuti.com/components/button/) |
| IconButton | ShadIconButton | [docs](https://flutter-shadcn-ui.mariuti.com/components/icon-button/) |
| Input | ShadInput | [docs](https://flutter-shadcn-ui.mariuti.com/components/input/) |
| Textarea | ShadTextarea | [docs](https://flutter-shadcn-ui.mariuti.com/components/textarea/) |
| Card | ShadCard | [docs](https://flutter-shadcn-ui.mariuti.com/components/card/) |
| Dialog | ShadDialog | [docs](https://flutter-shadcn-ui.mariuti.com/components/dialog/) |
| Alert | ShadAlert | [docs](https://flutter-shadcn-ui.mariuti.com/components/alert/) |
| Badge | ShadBadge | [docs](https://flutter-shadcn-ui.mariuti.com/components/badge/) |
| Separator | ShadSeparator | [docs](https://flutter-shadcn-ui.mariuti.com/components/separator/) |
| Avatar | ShadAvatar | [docs](https://flutter-shadcn-ui.mariuti.com/components/avatar/) |
| Popover | ShadPopover | [docs](https://flutter-shadcn-ui.mariuti.com/components/popover/) |
| Calendar | ShadCalendar | [docs](https://flutter-shadcn-ui.mariuti.com/components/calendar/) |
| Tabs | ShadTabs | [docs](https://flutter-shadcn-ui.mariuti.com/components/tabs/) |
| DropdownMenu | ShadContextMenu | [docs](https://flutter-shadcn-ui.mariuti.com/components/context-menu/) |
| Checkbox | ShadCheckbox | [docs](https://flutter-shadcn-ui.mariuti.com/components/checkbox/) |
| RadioGroup | ShadRadioGroup | [docs](https://flutter-shadcn-ui.mariuti.com/components/radio-group/) |
| Switch | ShadSwitch | [docs](https://flutter-shadcn-ui.mariuti.com/components/switch/) |
| Select | ShadSelect | [docs](https://flutter-shadcn-ui.mariuti.com/components/select/) |
| Toast | Sonner | [docs](https://flutter-shadcn-ui.mariuti.com/components/sonner/) |
| Sheet | ShadSheet | [docs](https://flutter-shadcn-ui.mariuti.com/components/sheet/) |

## 🔧 마이그레이션 예제

### 1. Button

**❌ Material (기존):**
```dart
import 'package:flutter/material.dart';

ElevatedButton(
  onPressed: _save,
  child: Text('common.save'.tr()),
)

IconButton(
  icon: Icon(AppIcons.add),
  onPressed: _add,
)
```

**✅ shadcn_ui (변경 후):**
```dart
import 'package:shadcn_ui/shadcn_ui.dart';

// 텍스트 버튼
ShadButton(
  onPressed: _save,
  child: Text('common.save'.tr()),
)

ShadButton.outline(
  onPressed: _save,
  child: Text('common.save'.tr()),
)

ShadButton.destructive(
  onPressed: _delete,
  child: Text('common.delete'.tr()),
)

// 아이콘 버튼 (ShadIconButton 사용)
ShadIconButton.ghost(
  icon: Icon(AppIcons.add),
  onPressed: _add,
)

ShadIconButton.outline(
  icon: Icon(AppIcons.settings),
  onPressed: _openSettings,
)
```

### 2. Input

**❌ Material (기존):**
```dart
TextField(
  controller: _controller,
  decoration: InputDecoration(
    hintText: 'snap.input_placeholder'.tr(),
    border: OutlineInputBorder(),
  ),
  maxLines: null,
  minLines: 2,
  maxLength: 300,
)
```

**✅ shadcn_ui (변경 후):**
```dart
ShadInput(
  controller: _controller,
  placeholder: Text('snap.input_placeholder'.tr()),
  maxLength: 300,
)

// 다줄 입력
ShadTextarea(
  controller: _controller,
  placeholder: Text('snap.input_placeholder'.tr()),
  minLines: 2,
  maxLines: 5,
  maxLength: 300,
)
```

### 3. Card

**❌ Material (기존):**
```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Title'),
        Text('Content'),
      ],
    ),
  ),
)
```

**✅ shadcn_ui (변경 후):**
```dart
ShadCard(
  title: Text('Title'),
  description: Text('Description'),
  child: Column(
    children: [
      Text('Content'),
    ],
  ),
)
```

### 4. Dialog

**❌ Material (기존):**
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('draft.delete_title'.tr()),
    content: Text('draft.delete_confirm'.tr()),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('common.cancel'.tr()),
      ),
      TextButton(
        onPressed: () {
          _delete();
          Navigator.pop(context);
        },
        child: Text('common.delete'.tr()),
      ),
    ],
  ),
);
```

**✅ shadcn_ui (변경 후):**
```dart
showShadDialog(
  context: context,
  builder: (context) => ShadDialog(
    title: Text('draft.delete_title'.tr()),
    description: Text('draft.delete_confirm'.tr()),
    actions: [
      ShadButton.outline(
        onPressed: () => Navigator.pop(context),
        child: Text('common.cancel'.tr()),
      ),
      ShadButton.destructive(
        onPressed: () {
          _delete();
          Navigator.pop(context);
        },
        child: Text('common.delete'.tr()),
      ),
    ],
  ),
);
```

### 5. Alert

**❌ Material (기존):**
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: theme.colorScheme.errorContainer,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      Icon(AppIcons.error, color: theme.colorScheme.error),
      SizedBox(width: 8),
      Expanded(
        child: Text(
          'timeline.error_loading'.tr(),
          style: TextStyle(color: theme.colorScheme.onErrorContainer),
        ),
      ),
    ],
  ),
)
```

**✅ shadcn_ui (변경 후):**
```dart
ShadAlert.destructive(
  icon: Icon(AppIcons.error),
  title: Text('timeline.error_loading'.tr()),
  description: Text(error.toString()),
)
```

### 6. Separator

**❌ Material (기존):**
```dart
Divider(
  height: 1,
  color: theme.colorScheme.outline.withOpacity(0.2),
)
```

**✅ shadcn_ui (변경 후):**
```dart
const ShadSeparator()

// 세로 구분선
const ShadSeparator.vertical()
```

## 📋 Import 변경

**기존:**
```dart
import 'package:flutter/material.dart';
```

**변경 후:**
```dart
import 'package:flutter/material.dart';  // 기본 위젯용 (Scaffold, Column 등)
import 'package:shadcn_ui/shadcn_ui.dart';  // shadcn_ui 컴포넌트용
```

## ⚠️ 주의사항

### 1. ShadApp.custom 사용 (필수)

**이 프로젝트는 `ShadApp.custom`으로 MaterialApp을 감쌉니다.**

**✅ 현재 방식 (ShadApp.custom + MaterialApp + shadcn_ui):**
```dart
import 'package:shadcn_ui/shadcn_ui.dart';

ShadApp.custom(
  themeMode: themeMode,
  theme: ShadThemeData(
    brightness: Brightness.light,
    colorScheme: const ShadSlateColorScheme.light(),
  ),
  darkTheme: ShadThemeData(
    brightness: Brightness.dark,
    colorScheme: const ShadSlateColorScheme.dark(),
  ),
  appBuilder: (context) {
    return MaterialApp.router(
      theme: common.AppTheme.lightTheme(seedColor: seedColor),
      darkTheme: common.AppTheme.darkTheme(seedColor: seedColor),
      themeMode: themeMode,
      routerConfig: router.appRouter,
      builder: (context, child) {
        return ShadAppBuilder(child: child!);
      },
    );
  },
)
```

**이유:**
- shadcn_ui 컴포넌트가 `ShadTheme` 컨텍스트를 요구함
- `ShadApp.custom`으로 MaterialApp 감싸고 `ShadAppBuilder`로 라우터 자식 감싸기
- `minorlab_common` 패키지의 `AppTheme` 계속 사용 (Material Theme)
- Material 기본 위젯과 shadcn_ui 컴포넌트 혼용 가능
- Scaffold, AppBar 등은 Material 유지

### 2. 테마 시스템

**Shadcn Theme 사용 (ShadTheme.of(context)):**

```dart
import 'package:shadcn_ui/shadcn_ui.dart';

final theme = ShadTheme.of(context);

// ✅ Shadcn 색상 사용
Container(
  color: theme.colorScheme.muted,  // bg-muted
  child: Text(
    'Text',
    style: TextStyle(color: theme.colorScheme.mutedForeground),
  ),
)
```

**Material Design → Shadcn 색상 매핑:**

| Material Design | Shadcn Theme | 용도 | 예시 |
|----------------|--------------|------|------|
| `colorScheme.onSurfaceVariant` | `theme.colorScheme.mutedForeground` | 보조 텍스트, 아이콘 | Fragment 메타데이터 |
| `colorScheme.surfaceVariant` | `theme.colorScheme.muted` | 배경, 카드 | AI 태그 배경 |
| `colorScheme.outline` | `theme.colorScheme.border` | 테두리 | 카드 테두리 |
| `colorScheme.primary` | `theme.colorScheme.primary` | 강조 색상 (동일) | 버튼, 링크 |

**❌ Material Design (기존):**
```dart
Text(
  'Secondary text',
  style: TextStyle(color: colorScheme.onSurfaceVariant),
)
```

**✅ Shadcn Theme (변경 후):**
```dart
final theme = ShadTheme.of(context);
Text(
  'Secondary text',
  style: TextStyle(color: theme.colorScheme.mutedForeground),
)
```

### 3. 아이콘

**AppIcons 계속 사용:**
```dart
ShadButton.ghost(
  icon: Icon(AppIcons.add),  // ✅ AppIcons 사용
  onPressed: _add,
)
```

### 4. 다국어

**기존 방식 유지 (.tr()):**
```dart
ShadButton(
  onPressed: _save,
  child: Text('common.save'.tr()),  // ✅ .tr() 사용
)
```

## 🚀 향후 마이그레이션 계획 (선택 사항)

웹과 완전한 동등성이 필요한 경우 아래 순서로 점진적 마이그레이션 가능:

1. **Button / IconButton** → ShadButton / ShadButton.ghost
2. **TextField** → ShadInput / ShadTextarea
3. **Card** → ShadCard
4. **AlertDialog** → ShadDialog
5. **Divider** → ShadSeparator
6. **기타 컴포넌트** (필요 시)

**현재**: Material UI 우선 사용, 필요 시에만 shadcn_ui 선택

## 📚 참고 자료

- [Flutter Shadcn UI 공식 문서](https://flutter-shadcn-ui.mariuti.com/)
- [웹 버전 (shadcn-svelte)](https://www.shadcn-svelte.com/)
- [원본 shadcn/ui](https://ui.shadcn.com/)
