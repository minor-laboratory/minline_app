# Fragment 입력 방식 옵션 Implementation

## ⚠️ 구현 시 주의사항 (반드시 확인)

### 입력 UI 관리 위치

- **MainPage에서 관리** → TimelineView에서 관리 금지
  - 이유: 모든 탭(Timeline/Drafts/Posts)에서 입력 UI 표시 필요
  - TimelineView는 Fragment 목록만 표시
- **Stack + Positioned 사용** → 하단 입력창 레이아웃
  - inline 모드: `if (inputMode == 'inline')` Positioned로 하단 배치
  - fab 모드: `floatingActionButton` 파라미터 사용

### 알림 처리 로직

- **현재 탭 체크 불필요** → MainPage에 항상 입력 UI 존재
  - 잘못된 방식: `if (_currentPageIndex == 0)` 체크
  - 올바른 방식: 바로 inputMode만 체크
- **index 0 (타임라인 요청) 시:**
  - inline 모드 → 입력창 포커스 (`_timelineFocusTrigger?.call()`)
  - fab 모드 → 모달 표시 (`_showFragmentInputModal()`)

### 색상 및 스타일

- **Modal 배경색: theme.colorScheme.muted** → background 사용 금지
  - 이유: StandardBottomSheet와 일치 필요
  - `showModalBottomSheet()` builder에서 Container 색상 지정
- **아이콘: AppIcons.xxx 사용** → Icons.xxx 금지
  - FAB: `Icon(AppIcons.add)`
  - 설정: `Icon(AppIcons.edit)`

### SharedPreferences 저장

- **기본값: 'inline'** → 다른 값 금지
- **허용 값: 'inline' 또는 'fab'** → 다른 값은 setInputMode()에서 무시
- **Analytics 이벤트** → fragment_input_mode_changed 전송 필수

### 테스트 실패 흔한 케이스

- [ ] 설정 변경 후 UI가 즉시 반영되지 않음 → ref.watch() 사용 확인
- [ ] 알림 탭 시 아무 동작 없음 → MainPage.onTabChangeRequested 콜백 설정 확인
- [ ] modal과 header 배경색 불일치 → theme.colorScheme.muted 사용 확인
- [ ] Timeline 탭에서만 입력 UI 표시 → Stack을 PageView 밖에 배치 확인

## 핵심 파일 및 API

### FragmentInputModeNotifier

**위치:** `lib/features/settings/providers/settings_provider.dart`

**시그니처:**
```dart
@riverpod
class FragmentInputModeNotifier extends _$FragmentInputModeNotifier {
  @override
  Future<String> build() async { ... }

  Future<void> setInputMode(String mode) async { ... }
}
```

**실수하기 쉬운 점:**
- mode는 'inline' 또는 'fab'만 허용
- 다른 값 전달 시 조용히 무시 (에러 발생 안함)
- SharedPreferences 저장 완료 후 state 업데이트 필수

### MainPage 입력 UI 관리

**위치:** `lib/features/main/presentation/pages/main_page.dart`

**구조:**
```dart
@override
Widget build(BuildContext context) {
  final inputModeAsync = ref.watch(fragmentInputModeProvider);
  final inputMode = inputModeAsync.asData?.value ?? 'inline';

  return Scaffold(
    body: Stack(
      children: [
        PageView(...),  // 탭 페이지들
        // inline 모드일 때만 입력창 표시
        if (inputMode == 'inline')
          Positioned(
            bottom: 0,
            child: KeyboardAnimationBuilder(
              builder: (context, keyboardHeight) => ...,
            ),
          ),
      ],
    ),
    // fab 모드일 때만 FAB 표시
    floatingActionButton: inputMode == 'fab' ? FloatingActionButton(...) : null,
  );
}
```

**실수하기 쉬운 점:**
- `if`문 누락 시 둘 다 표시됨
- Positioned를 PageView 내부에 배치하면 Timeline 탭에서만 표시
- KeyboardAnimationBuilder를 Positioned 밖에 두면 ParentDataWidget 에러

### 알림 처리 콜백

**위치:** `lib/features/main/presentation/pages/main_page.dart` (initState)

**구조:**
```dart
MainPage.onTabChangeRequested = (index) async {
  if (!mounted || index < 0 || index > 2) return;

  if (index == 0) {
    final inputMode = await ref.read(fragmentInputModeProvider.future);

    if (inputMode == 'inline') {
      _timelineFocusTrigger?.call();  // 입력창 포커스
    } else {
      _showFragmentInputModal();  // 모달 표시
    }
  } else {
    // 다른 탭으로 이동
    setState(() => _currentPageIndex = index);
    _pageController.jumpToPage(index);
  }
};
```

**실수하기 쉬운 점:**
- `if (_currentPageIndex == 0)` 체크는 불필요 (MainPage에 항상 입력 UI 존재)
- `_timelineFocusTrigger`가 null일 수 있음 (null 체크 필수)
- mounted 체크 누락 시 dispose 후 setState 에러

## 기존 코드 통합

**수정 필요한 파일:**
- `lib/features/timeline/presentation/widgets/timeline_view.dart`
  - FragmentInputBar 제거
  - KeyboardAnimationBuilder 제거
  - onRegisterFocusTrigger 파라미터 제거
  - 단순히 FragmentList 또는 CalendarView만 표시

- `lib/features/main/presentation/pages/main_page.dart`
  - Stack 구조로 변경 (PageView + 입력 UI)
  - fragmentInputModeProvider watch
  - 조건부 입력 UI 표시

- `lib/features/settings/presentation/pages/settings_page.dart`
  - 입력 방식 설정 ListTile 추가
  - 바텀시트로 선택 UI 제공

**참고할 유사 기능:**
- AutoFocusInputNotifier (`lib/features/settings/providers/settings_provider.dart`)
  - SharedPreferences 저장 패턴 동일
  - Analytics 이벤트 전송 패턴 동일

- StandardBottomSheet (`lib/shared/widgets/standard_bottom_sheet.dart`)
  - 배경색: `theme.colorScheme.card` 사용
  - 입력 모달도 동일한 색상 사용해야 일관성 유지

**Modal/Sheet 구현 시:**
[MOBILE_DIALOG_SHEET_RULES.md](../../MOBILE_DIALOG_SHEET_RULES.md) 읽을 것
- isScrollControlled: true 필수
- backgroundColor: Colors.transparent
- Container에서 실제 배경색 지정

## UI 구현

**레이아웃 패턴:** 채팅 앱 스타일 입력창

**재사용 컴포넌트:**
- FragmentInputBar: Timeline에서 MainPage로 이동
- KeyboardAnimationBuilder: 키보드 애니메이션 처리
- StandardBottomSheet: 설정 선택 UI

**색상 사용:**
```dart
final theme = ShadTheme.of(context);

// Modal 배경
color: theme.colorScheme.muted

// Modal 핸들
color: theme.colorScheme.mutedForeground

// 텍스트
style: TextStyle(color: theme.colorScheme.foreground)
```

**아이콘 사용:**
- AppIcons.add (FAB)
- AppIcons.edit (설정 아이콘)
- AppIcons.chevronRight (설정 trailing)

## 설정 UI 구현

**위치:** `lib/features/settings/presentation/pages/settings_page.dart`

**구조:**
```dart
Consumer(
  builder: (context, ref, child) {
    final inputModeAsync = ref.watch(fragmentInputModeProvider);

    return inputModeAsync.when(
      data: (mode) => ListTile(
        leading: Icon(AppIcons.edit),
        title: Text('settings.fragment_input_mode'.tr()),
        subtitle: Text(_getInputModeLabel(mode)),
        trailing: Icon(AppIcons.chevronRight, size: 20),
        onTap: () => _showInputModeSettings(mode),
      ),
      loading: () => ...,
      error: (_, __) => ...,
    );
  },
)
```

**바텀시트 내용:**
- inline 모드: '하단 입력창' + 설명
- fab 모드: '플로팅 버튼' + 설명
- 현재 선택 항목 표시

## 단위 테스트

### FragmentInputModeNotifier

- [ ] 기본값: 'inline' 반환
- [ ] setInputMode('inline') → SharedPreferences 저장 확인
- [ ] setInputMode('fab') → SharedPreferences 저장 확인
- [ ] setInputMode('invalid') → 저장 안됨 (무시)
- [ ] Analytics 이벤트 전송 확인

### MainPage 입력 UI

- [ ] inputMode = 'inline' → 하단 입력창 표시, FAB 없음
- [ ] inputMode = 'fab' → FAB 표시, 하단 입력창 없음
- [ ] 모드 변경 시 즉시 UI 반영
- [ ] 모든 탭에서 입력 UI 표시 (Timeline/Drafts/Posts)

### 알림 처리

- [ ] index = 0, inline 모드 → _timelineFocusTrigger 호출
- [ ] index = 0, fab 모드 → _showFragmentInputModal 호출
- [ ] index = 1 → Drafts 탭으로 이동
- [ ] index = 2 → Posts 탭으로 이동
- [ ] mounted = false → 아무 동작 없음

### Settings UI

- [ ] inputMode 표시 정확성
- [ ] ListTile 탭 → 바텀시트 표시
- [ ] 바텀시트에서 선택 → 설정 저장
- [ ] 설정 변경 → MainPage UI 즉시 반영

## 자주 하는 실수

1. **TimelineView에서 입력 관리** → MainPage에서 관리해야 함
   - 이유: 모든 탭에서 입력 UI 필요

2. **현재 탭 체크** → 불필요 (MainPage에 항상 입력 UI 존재)
   - 잘못된 코드: `if (_currentPageIndex == 0) { ... }`

3. **Modal 배경색 theme.colorScheme.background 사용** → muted 사용
   - StandardBottomSheet와 일치시켜야 함

4. **둘 다 표시** → `if (inputMode == 'inline')` 조건문 필수
   - 조건문 없으면 입력창과 FAB가 동시에 표시됨

5. **PageView 내부에 Positioned 배치** → Stack을 PageView 밖에 두어야 함
   - 잘못된 구조: `PageView(children: [Positioned(...)])`
   - 올바른 구조: `Stack(children: [PageView(...), Positioned(...)])`

6. **KeyboardAnimationBuilder 위치** → Positioned 내부에 배치
   - ParentDataWidget 에러 발생 주의

7. **Translation 키 누락** → ko.json, en.json 모두 추가 필수
   - fragment_input_mode, input_mode_inline, input_mode_fab 등

8. **Analytics 이벤트 누락** → setInputMode()에서 반드시 전송
   - 이벤트명: fragment_input_mode_changed
   - 파라미터: {'mode': mode}

## 성능 고려사항

- **ref.watch() 사용** → 설정 변경 시에만 rebuild
  - 불필요한 rebuild 방지

- **KeyboardAnimationBuilder** → 키보드 애니메이션 최적화
  - 키보드 높이 변화만 감지하여 rebuild

- **fragmentInputModeProvider** → AsyncValue 캐싱
  - SharedPreferences 중복 읽기 방지

## 관련 문서

- [Feature 문서](./FEATURE.md)
- [설정 관리 가이드](/docs/flutter/USER_STATE_MANAGEMENT_GUIDE.md) - SharedPreferences 패턴 참조 시
- [컴포넌트 명세](../../COMPONENT_SPECS.md) - FragmentInputBar 구조 이해 시
- [Modal/Dialog/Sheet 규칙](../../MOBILE_DIALOG_SHEET_RULES.md) - 입력 모달 구현 시 (필수)
- [Shadcn Theme 마이그레이션](../../docs/MIGRATION_SHADCN.md) - 색상 사용법 확인 시

---

**작성 후 확인:**
- [x] "⚠️ 구현 시 주의사항"이 충분한가? (입력 UI 위치, 알림 처리, 색상)
- [x] "실수하기 쉬운 점"을 명시했는가? (8가지 실수 케이스)
- [x] 관련 문서에 "언제 읽어야 하는지" 있는가? (각 문서에 명시)
- [x] 단위 테스트 케이스가 완전한가? (Provider, UI, 알림, Settings)
- [x] 500-1000줄 이내인가? (약 350줄)
