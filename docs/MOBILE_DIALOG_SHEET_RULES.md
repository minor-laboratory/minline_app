# 모바일 Dialog & Sheet 사용 규칙

> **작성일**: 2025-11-13
> **프로젝트**: MiniLine App (Flutter)
> **기반**: /docs/common/GUIDE_STYLE_COMPONENTS.md 원칙

**언제 읽어야 하는가:**
- Dialog, Sheet, Modal 구현 전 (필수)
- 사용자 입력 받는 UI 설계 시
- 설정/선택 화면 구현 시

---

## 🎯 핵심 원칙

### 1. 텍스트 입력이 필요한 경우
**❌ Dialog/Sheet 사용 금지**
**✅ 페이지로 구현**

```dart
// ❌ 절대 금지
showShadDialog(
  context: context,
  builder: (context) => ShadDialog(
    title: Text('edit_name.title'.tr()),
    child: ShadInput(  // 텍스트 입력 금지!
      placeholder: Text('name'.tr()),
    ),
  ),
);

showShadSheet(
  context: context,
  builder: (context) => ShadSheet(
    child: ShadTextarea(),  // 텍스트 입력 금지!
  ),
);

// ✅ 올바른 방법: 페이지로 구현
// 1. 라우트 정의
GoRoute(
  path: '/settings/edit-name',
  builder: (context, state) => EditNamePage(),
)

// 2. 페이지로 이동
context.push('/settings/edit-name');

// 3. 페이지 구현
class EditNamePage extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('edit_name.title'.tr()),
        actions: [
          ShadButton.ghost(
            onPressed: _save,
            child: Text('common.save'.tr()),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ShadInput(
          controller: _nameController,
          placeholder: Text('name'.tr()),
        ),
      ),
    );
  }
}
```

### 2. Dialog 사용 허용 (제한적)
**단순 확인/삭제만** 허용

```dart
// ✅ 허용: 삭제 확인
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

if (confirmed == true) {
  await _deleteDraft();
}

// ✅ 허용: 단순 정보 표시
showShadDialog(
  context: context,
  builder: (context) => ShadDialog.alert(
    title: Text('info.title'.tr()),
    description: Text('info.message'.tr()),
    actions: [
      ShadButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text('common.ok'.tr()),
      ),
    ],
  ),
);
```

### 3. Sheet 사용 허용
**설정 선택, 리스트 선택** 허용

```dart
// ✅ 허용: 테마 선택
showShadSheet(
  context: context,
  side: ShadSheetSide.bottom,
  builder: (context) => ShadSheet(
    title: Text('settings.theme'.tr()),
    description: Text('settings.theme_desc'.tr()),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildThemeOption('light'),
        _buildThemeOption('dark'),
        _buildThemeOption('system'),
      ],
    ),
  ),
);

Widget _buildThemeOption(String theme) {
  return ListTile(
    title: Text('theme.$theme'.tr()),
    leading: Icon(_getThemeIcon(theme)),
    trailing: _currentTheme == theme
      ? Icon(AppIcons.checkCircle)
      : null,
    onTap: () {
      _setTheme(theme);
      Navigator.of(context).pop();
    },
  );
}

// ✅ 허용: 언어 선택
showShadSheet(
  context: context,
  side: ShadSheetSide.bottom,
  builder: (context) => ShadSheet(
    title: Text('settings.language'.tr()),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text('한국어'),
          onTap: () {
            context.setLocale(Locale('ko'));
            Navigator.of(context).pop();
          },
        ),
        ListTile(
          title: Text('English'),
          onTap: () {
            context.setLocale(Locale('en'));
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  ),
);
```

---

## 📋 사용 케이스별 가이드

### 케이스 1: 이름 변경
```dart
// ❌ 잘못: Dialog 사용
showShadDialog(
  context: context,
  builder: (context) => ShadDialog(
    child: ShadInput(),  // 금지!
  ),
);

// ✅ 올바름: 페이지 사용
context.push('/settings/edit-name');
```

### 케이스 2: 비밀번호 변경
```dart
// ❌ 잘못: Sheet 사용
showShadSheet(
  context: context,
  builder: (context) => ShadSheet(
    child: Column(
      children: [
        ShadInput(placeholder: Text('current_password'.tr())),
        ShadInput(placeholder: Text('new_password'.tr())),
      ],
    ),
  ),
);

// ✅ 올바름: 페이지 사용
context.push('/settings/change-password');
```

### 케이스 3: Draft 삭제
```dart
// ✅ 올바름: Dialog 사용
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
```

### 케이스 4: 정렬 방식 선택
```dart
// ❌ 잘못: Dialog 사용
showShadDialog(
  context: context,
  builder: (context) => ShadDialog(
    child: Column(children: [...]),
  ),
);

// ✅ 올바름: Sheet 사용
showShadSheet(
  context: context,
  side: ShadSheetSide.bottom,
  builder: (context) => ShadSheet(
    title: Text('filter.sort'.tr()),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text('filter.sort_event'.tr()),
          onTap: () {
            _setSortBy('event');
            Navigator.of(context).pop();
          },
        ),
        ListTile(
          title: Text('filter.sort_created'.tr()),
          onTap: () {
            _setSortBy('created');
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  ),
);
```

### 케이스 5: 알림 시간 설정
```dart
// ❌ 잘못: Dialog에 TimePicker
showShadDialog(
  context: context,
  builder: (context) => ShadDialog(
    child: TimePickerWidget(),  // 복잡한 입력 금지!
  ),
);

// ✅ 올바름: Sheet 사용
showShadSheet(
  context: context,
  side: ShadSheetSide.bottom,
  builder: (context) => ShadSheet(
    title: Text('settings.reminder_time'.tr()),
    child: Container(
      height: 300,
      child: CupertinoTimerPicker(
        mode: CupertinoTimerPickerMode.hm,
        initialTimerDuration: _currentTime,
        onTimerDurationChanged: (duration) {
          setState(() => _selectedTime = duration);
        },
      ),
    ),
    actions: [
      ShadButton(
        onPressed: () {
          _saveTime(_selectedTime);
          Navigator.of(context).pop();
        },
        child: Text('common.save'.tr()),
      ),
    ],
  ),
);
```

---

## 🎨 디자인 가이드라인

### Dialog 디자인
- **최소 정보**: 제목 + 설명 + 버튼 1-2개
- **버튼 배치**: 오른쪽 정렬 (취소/확인 순서)
- **파괴적 액션**: Destructive 버튼 사용
- **닫기**: 뒤로가기/외부 탭으로 닫힘

```dart
ShadDialog(
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
)
```

### Sheet 디자인
- **제목**: 필수
- **설명**: 선택적
- **드래그 핸들**: 자동 (shadcn_ui)
- **높이**: 자동 (내용에 따라)
- **최대 높이**: 화면의 90%

```dart
ShadSheet(
  title: Text('settings.theme'.tr()),
  description: Text('settings.theme_desc'.tr()),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // 리스트 아이템들
    ],
  ),
)
```

### 페이지 디자인
- **AppBar**: 제목 + 저장 버튼
- **Body**: 입력 필드들
- **패딩**: 16dp
- **키보드**: 자동 올라감

```dart
Scaffold(
  appBar: AppBar(
    title: Text('edit_name.title'.tr()),
    actions: [
      ShadButton.ghost(
        onPressed: _isValid ? _save : null,
        child: Text('common.save'.tr()),
      ),
    ],
  ),
  body: Padding(
    padding: EdgeInsets.all(16),
    child: ShadInput(
      controller: _controller,
      placeholder: Text('name'.tr()),
      autofocus: true,
    ),
  ),
)
```

---

## ⚠️ 자주 하는 실수

### 실수 1: Dialog에 텍스트 입력
```dart
// ❌ 잘못
showShadDialog(
  context: context,
  builder: (context) => ShadDialog(
    title: Text('edit_name.title'.tr()),
    child: ShadInput(),  // 금지!
  ),
);

// ✅ 올바름
context.push('/edit-name');
```

### 실수 2: Sheet에 복잡한 폼
```dart
// ❌ 잘못
showShadSheet(
  context: context,
  builder: (context) => ShadSheet(
    child: Form(
      child: Column(
        children: [
          ShadInput(),      // 여러 개 입력 금지!
          ShadInput(),
          ShadTextarea(),
        ],
      ),
    ),
  ),
);

// ✅ 올바름: 페이지 사용
context.push('/create-post');
```

### 실수 3: 단순 선택에 페이지 사용
```dart
// ❌ 잘못: 단순 선택을 페이지로
context.push('/select-theme');  // 과함!

// ✅ 올바름: Sheet 사용
showShadSheet(
  context: context,
  builder: (context) => ShadSheet(
    title: Text('settings.theme'.tr()),
    child: ThemeSelector(),
  ),
);
```

---

## 📋 의사결정 플로우차트

```
사용자 입력이 필요한가?
│
├─ YES: 텍스트/복잡한 입력?
│  ├─ YES: 페이지 사용 ✅
│  └─ NO: 단순 선택?
│     ├─ YES: Sheet 사용 ✅
│     └─ NO: Dialog 사용 ✅
│
└─ NO: 단순 정보 표시/확인?
   ├─ YES: Dialog 사용 ✅
   └─ NO: 설계 재검토 필요
```

### 예시

| 기능 | 입력 타입 | 사용할 것 | 이유 |
|------|----------|----------|------|
| 이름 변경 | 텍스트 입력 | 페이지 | 텍스트 입력 필요 |
| Draft 삭제 | 확인만 | Dialog | 단순 확인 |
| 테마 선택 | 단순 선택 | Sheet | 3개 옵션 선택 |
| 언어 선택 | 단순 선택 | Sheet | 2개 옵션 선택 |
| Post 작성 | 복잡한 입력 | 페이지 | 여러 필드 입력 |
| 정렬 방식 | 단순 선택 | Sheet | 3-4개 옵션 선택 |
| 알림 시간 | 시간 선택 | Sheet | TimePicker 사용 |
| **태그 추가** | **텍스트 입력** | **페이지** | **실제 구현 예시** |

### 실제 구현 예시: Fragment 태그 추가

**참조**: [COMPONENT_SPECS.md - TagEditPage](COMPONENT_SPECS.md#6-tageditpage-태그-추가-페이지)

#### 1. 라우트 정의

```dart
// lib/router/app_router.dart
GoRoute(
  path: '/',
  name: 'timeline',
  routes: [
    GoRoute(
      path: 'tag/edit/:fragmentId',
      builder: (context, state) {
        final fragmentId = state.pathParameters['fragmentId']!;
        return TagEditPage(fragmentId: fragmentId);
      },
    ),
  ],
),
```

#### 2. 페이지 구현

```dart
// lib/features/timeline/presentation/pages/tag_edit_page.dart
class TagEditPage extends StatefulWidget {
  final String fragmentId;

  const TagEditPage({super.key, required this.fragmentId});

  @override
  State<TagEditPage> createState() => _TagEditPageState();
}

class _TagEditPageState extends State<TagEditPage> {
  final _tagController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 페이지 진입 시 자동 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _tagController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _save() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty) return;

    // 결과 반환하고 페이지 닫기
    context.pop(tag);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('tag.add_tag'.tr()),
        leading: IconButton(
          icon: Icon(AppIcons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          ShadButton(
            enabled: _tagController.text.trim().isNotEmpty,
            onPressed: _save,
            child: Text('common.save'.tr()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'tag.add_tag_description'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            ShadInput(
              controller: _tagController,
              focusNode: _focusNode,
              placeholder: Text('tag.add_tag_placeholder'.tr()),
              onChanged: (value) => setState(() {}),
              onSubmitted: (value) => _save(),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.info, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'tag.hint'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 3. 호출 및 결과 처리

```dart
// lib/features/timeline/presentation/widgets/fragment_card.dart
Future<void> _showAddTagPage() async {
  final tag = await context.push<String>('/tag/edit/${widget.fragment.remoteID}');

  if (tag != null && tag.isNotEmpty) {
    final isar = DatabaseService.instance.isar;
    await isar.writeTxn(() async {
      // Isar 트랜잭션 내부에서 다시 읽기 (필수)
      final fragment = await isar.fragments.get(widget.fragment.id);
      if (fragment == null) return;

      if (!fragment.userTags.contains(tag)) {
        fragment.userTags.add(tag);
        fragment.synced = false;
        fragment.refreshAt = DateTime.now();
        await isar.fragments.put(fragment);
      }
    });

    widget.onUpdate?.call();
  }
}
```

**왜 페이지를 사용했는가?**
- ✅ 텍스트 입력 필요 → 페이지 사용 원칙
- ✅ 키보드가 자동으로 올라오고 관리됨
- ✅ AppBar에 저장/취소 버튼 배치 가능
- ✅ 추가 설명 텍스트와 힌트 표시 공간 확보
- ✅ Enter 키로 저장, ESC/뒤로가기로 취소

**Dialog/Sheet를 사용하지 않은 이유:**
- ❌ 키보드가 Dialog를 가림
- ❌ 저장/취소 버튼 배치가 어색함
- ❌ 설명 텍스트 추가 공간 부족
- ❌ 모바일 UX 가이드라인 위반

---

## 📋 체크리스트

**구현 전 확인:**
- [ ] 텍스트 입력 필요? → 페이지 사용
- [ ] 복잡한 폼 필요? → 페이지 사용
- [ ] 단순 확인/삭제? → Dialog 사용
- [ ] 단순 선택 (2-5개)? → Sheet 사용
- [ ] 시간/날짜 선택? → Sheet 사용

**Dialog 사용 시:**
- [ ] 텍스트 입력 없음
- [ ] 버튼 1-2개만
- [ ] 제목 + 설명 명확
- [ ] 파괴적 액션은 Destructive 버튼

**Sheet 사용 시:**
- [ ] 제목 필수
- [ ] 드래그로 닫기 가능
- [ ] 옵션 개수 적절 (2-10개)
- [ ] mainAxisSize.min 사용

**페이지 사용 시:**
- [ ] AppBar에 저장 버튼
- [ ] autofocus 설정
- [ ] 유효성 검사 구현
- [ ] 키보드 자동 올라감

---

## 🔗 참고 문서

- [/docs/common/GUIDE_STYLE_COMPONENTS.md](/docs/common/GUIDE_STYLE_COMPONENTS.md) - 루트 가이드 (원칙)
- [docs/SHADCN_UI_COMPONENTS_GUIDE.md](SHADCN_UI_COMPONENTS_GUIDE.md) - shadcn_ui 사용법
- [docs/DESIGN_UI.md](DESIGN_UI.md) - UI 설계
