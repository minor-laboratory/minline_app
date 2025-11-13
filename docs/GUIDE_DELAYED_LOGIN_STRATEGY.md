# 지연 로그인 전략 (Delayed Login Strategy)

**작성일**: 2025-01-13
**적용 대상**: 미니라인 앱, 미니라인 웹

## 개요

사용자가 앱/웹에 처음 진입했을 때 **즉시 로그인을 요구하지 않고**, 콘텐츠 작성을 시도할 때 로그인을 유도하는 전략입니다.

## 목적

1. **진입 장벽 최소화** - 앱 설치 후 바로 입력 가능
2. **자연스러운 전환** - 저장이 필요한 시점에만 로그인 요청
3. **사용자 경험 개선** - "일단 써보고 마음에 들면 저장" 플로우

## 현재 상황 (Before)

### 북랩 패턴
```dart
// 익명 로그인 자동 실행 (앱 시작 시)
await supabase.auth.signInAnonymously();

// 로그아웃 시 익명으로 전환
await supabase.auth.signOut();
await supabase.auth.signInAnonymously();
```

**문제점:**
- 익명 사용자 관리 복잡성 (RLS 정책, 데이터 마이그레이션)
- 미니라인에는 불필요 (짧은 입력 → 바로 저장 플로우)

## 새로운 전략 (After)

### 1. 앱 시작 시

**동작:**
- 로그인 상태 확인만 수행
- 비로그인 상태면 그대로 진행 (익명 로그인 없음)

```dart
// ❌ 기존 (북랩)
await supabase.auth.signInAnonymously();

// ✅ 새로운 방식 (미니라인)
final currentUser = supabase.auth.currentUser;
if (currentUser == null) {
  // 비로그인 상태로 진행
}
```

### 2. Fragment 입력 시

**동작:**
- 입력창은 항상 활성화
- 텍스트 입력 가능

**UI:**
```
┌─────────────────────────────┐
│ 오늘 어떤 생각을 하셨나요?    │
│ [입력창 - 항상 활성화]        │
│                             │
│ [저장] 버튼                  │
└─────────────────────────────┘
```

### 3. 저장 버튼 클릭 시 (핵심)

**분기 처리:**

```dart
Future<void> _handleSave() async {
  final currentUser = supabase.auth.currentUser;

  if (currentUser == null) {
    // 비로그인 → 로그인 유도
    final shouldLogin = await _showLoginPrompt();

    if (shouldLogin) {
      // 입력 내용을 임시 저장 (메모리)
      final tempContent = _contentController.text;

      // 로그인 페이지로 이동
      final loginSuccess = await context.push<bool>('/auth');

      if (loginSuccess == true) {
        // 로그인 성공 → 임시 내용으로 저장
        await _saveFragment(tempContent);
      }
    }
  } else {
    // 로그인 상태 → 바로 저장
    await _saveFragment(_contentController.text);
  }
}
```

**로그인 유도 다이얼로그:**
```
┌──────────────────────────────┐
│  💾 저장하려면 로그인이 필요해요 │
│                              │
│  작성한 내용을 저장하고        │
│  모든 기기에서 확인하세요       │
│                              │
│  [나중에]  [로그인하기]         │
└──────────────────────────────┘
```

### 4. 로그아웃 시

**동작:**
- Supabase 로그아웃만 수행
- 익명 전환 없음
- 홈 화면으로 이동

```dart
// ❌ 기존 (북랩)
await supabase.auth.signOut();
await supabase.auth.signInAnonymously();

// ✅ 새로운 방식 (미니라인)
await supabase.auth.signOut();
// 홈으로 이동 (비로그인 상태)
context.go('/');
```

## 로컬 데이터 처리

### 비로그인 상태
- **저장하지 않음** - 입력은 가능하지만 저장 시도 시 로그인 유도
- 또는 **SharedPreferences에 임시 저장** 후 로그인 시 서버 업로드 (선택적)

### 로그인 후
- Isar (로컬) + Supabase (서버) 동기화
- 북랩 패턴과 동일

## 구현 체크리스트

### 앱 (Flutter)

- [ ] 앱 시작 시 익명 로그인 제거
- [ ] Fragment 입력 시 로그인 체크 제거
- [ ] 저장 버튼 클릭 시 로그인 체크 추가
- [ ] 로그인 유도 다이얼로그 구현
- [ ] 임시 내용 보존 로직 구현
- [ ] 로그아웃 시 익명 전환 제거

### 웹 (SvelteKit)

- [ ] 동일한 패턴 적용
- [ ] localStorage에 임시 저장 (선택적)

## 예외 상황

### 1. 로그인 취소
- 입력한 내용은 그대로 유지
- 다시 저장 버튼을 누르면 재차 로그인 유도

### 2. 로그인 실패
- 에러 메시지 표시
- 입력 내용 보존

### 3. 네트워크 오류
- 로컬 저장 (Isar)
- 동기화는 백그라운드에서 재시도

## 북랩과의 차이점

| 항목 | 북랩 | 미니라인 |
|------|------|---------|
| 익명 로그인 | ✅ 자동 실행 | ❌ 없음 |
| 로그아웃 후 | 익명으로 전환 | 비로그인 상태 |
| 비로그인 시 저장 | 가능 (익명) | 불가 (로그인 유도) |
| 로그인 시점 | 앱 시작 또는 동기화 필요 시 | 저장 버튼 클릭 시 |

## 다국어 키

### 새로 추가할 키

```yaml
# auth.yaml
login_required_title: "저장하려면 로그인이 필요해요"
login_required_message: "작성한 내용을 저장하고 모든 기기에서 확인하세요"
login_later: "나중에"
login_now: "로그인하기"

# timeline.yaml (또는 fragments.yaml)
save_login_required: "저장하려면 로그인이 필요합니다"
```

## 참고

- [북랩 AuthRepository](../minorlab_book/lib/features/auth/data/auth_repository.dart) - 익명 로직 참조 (제거할 부분)
- [미니라인 DB 스키마](../miniline/docs/SPEC_DATABASE_SCHEMA.md) - RLS 정책 확인

## 주의사항

1. **RLS 정책 확인** - 서버에서 비로그인 사용자의 INSERT를 차단해야 함
2. **임시 저장 제한** - 메모리 또는 SharedPreferences에만 보관 (Isar 제외)
3. **UX 테스트** - 로그인 유도가 너무 빈번하지 않도록

---

**Next Steps:**
1. 이 문서 리뷰
2. 웹 팀과 동일 전략 합의
3. 구현 시작
