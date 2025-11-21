# 도움말 시스템 구현

> 구현 상세 및 가드레일

**언제 읽어야 하는가:**
- 도움말/배너/프리미엄 모달 수정 시
- 새로운 도움말 트리거 추가 시

## 파일 구조

```
lib/shared/widgets/
├── post_limit_banner.dart    # 무료 한도 배너
└── premium_sheet.dart        # 프리미엄 유도 시트

lib/features/
├── drafts/presentation/widgets/drafts_view.dart  # Empty State 개선
├── posts/presentation/widgets/posts_view.dart    # Empty State 개선
└── main/presentation/pages/main_page.dart        # Banner 통합

assets/translations/
├── ko.json  # limit, premium, help 섹션
└── en.json
```

## 핵심 컴포넌트

### PostLimitBanner

**위치**: Posts 탭 상단 (MainPage body Column 첫 번째)

**표시 조건**:
```dart
// 프리미엄이면 숨김
if (subscription.isPremium) return SizedBox.shrink();

// 사용량 0이면 숨김
if (subscription.freePostsCount == 0) return SizedBox.shrink();
```

**스타일 결정**:
```dart
final isWarning = subscription.freePostsCount >= 2;
final isExceeded = subscription.isFreeLimitExceeded;

// 배경색
backgroundColor = isExceeded
    ? destructive.withValues(alpha: 0.1)
    : isWarning
        ? primary.withValues(alpha: 0.1)
        : muted;
```

### PremiumSheet

**호출**:
```dart
// StandardBottomSheet 패턴 사용
PremiumSheet.show(context);
```

**구조**:
- 서브타이틀
- 비교 테이블 (3행: 글 생성, AI 분석, Storage)
- 기능 목록 (4개 항목 + checkCircle 아이콘)
- 업그레이드 버튼 (TODO: 인앱결제)
- 구매 복원 버튼

### Empty State 패턴

**디자인 가이드 준수**:
```dart
// 원형 아이콘 배경
Container(
  width: 80,
  height: 80,
  decoration: BoxDecoration(
    color: theme.colorScheme.muted,
    shape: BoxShape.circle,
  ),
  child: Icon(size: 40, color: mutedForeground),
)

// 힌트 박스
Container(
  padding: EdgeInsets.all(Spacing.md),
  decoration: BoxDecoration(
    color: muted.withValues(alpha: 0.5),
    borderRadius: BorderRadius.circular(BorderRadii.md),
  ),
  child: Row([Icon(info), Text(hint)]),
)
```

## 다국어 키

### limit 섹션
| 키 | 용도 |
|---|------|
| `free_posts_count` | "이번 달 {current}/{max}개 사용" |
| `free_posts_remaining` | "남은 무료 글: {remaining}개" |
| `free_limit_warning` | "이번 달 무료 글 생성이 {remaining}개 남았어요" |
| `reset_at` | "다음 리셋: {date}" |

### premium 섹션
| 키 | 용도 |
|---|------|
| `title` | 시트 타이틀 |
| `free_plan` / `premium_plan` | 테이블 헤더 |
| `feature_*` | 기능 목록 |
| `upgrade_button` | CTA 버튼 |

### help 섹션
| 키 | 용도 |
|---|------|
| `draft_empty_title` | Draft Empty State 제목 |
| `draft_empty_desc` | Draft Empty State 설명 |
| `draft_first_visit` | Draft 힌트 박스 |
| `post_empty_*` | Post Empty State |

## 주의사항

### 1. 배너 위치
```dart
// MainPage body 구조
Column([
  if (_currentPageIndex == 2) PostLimitBanner(...),  // Posts 탭만
  Expanded(child: Stack([PageView, FragmentInputBar])),
])
```

### 2. Provider 의존성
```dart
// PostLimitBanner는 subscriptionProvider 사용
final subscriptionAsync = ref.watch(subscriptionProvider);
```

### 3. 인앱결제 (TODO)
```dart
// 현재는 SnackBar로 "곧 출시됩니다" 표시
onPressed: () {
  Navigator.of(context).pop();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('premium.coming_soon'.tr())),
  );
}
```

## 테스트 체크리스트

- [ ] Empty State: Draft 탭 비어있을 때 새로운 UI 표시
- [ ] Empty State: Post 탭 비어있을 때 새로운 UI 표시
- [ ] 배너: 무료 사용자 + 1개 이상 사용 시 표시
- [ ] 배너: 프리미엄 사용자는 숨김
- [ ] 배너: 한도 임박(2/3) 시 primary 색상
- [ ] 배너: 한도 초과(3/3) 시 destructive 색상 + 업그레이드 링크
- [ ] PremiumSheet: 업그레이드 탭 시 표시
- [ ] PremiumSheet: 비교 테이블 정상 표시
- [ ] 다국어: 한글/영어 전환 시 모든 텍스트 정상

---

**작성 후 확인:**
- [x] ❌/✅ 패턴 사용했는가?
- [x] 파일 경로가 명확한가?
- [x] 핵심 코드 발췌했는가? (전체 복사 X)
- [x] TODO 항목이 명시되어 있는가?
