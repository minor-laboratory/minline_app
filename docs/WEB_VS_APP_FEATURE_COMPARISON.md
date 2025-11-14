# 웹 vs 앱 기능 비교 분석

> **작성일**: 2025-11-14
> **목적**: 미니라인 웹 버전과 앱 버전의 모든 기능/디자인 차이를 상세히 비교하여 누락된 기능과 버그를 식별

## 📋 목차
- [Fragment 비교](#fragment-비교)
- [Draft 비교](#draft-비교)
- [Post 비교](#post-비교)
- [수정 우선순위](#수정-우선순위)
- [예상 작업량](#예상-작업량)

---

## Fragment 비교

### ✅ 다국어 적용 상태
- **웹**: 모든 텍스트 `.tr()` 사용 ✅
- **앱**: 모든 텍스트 `.tr()` 사용 ✅
- **결론**: 하드코딩 없음. 완벽하게 적용됨.

### 🎨 UI/디자인 차이

#### 태그 칩 디자인

| 항목 | 웹 | 앱 | 비고 |
|-----|-----|-----|-----|
| **AI 태그** | | | |
| 배경 색상 | `bg-muted` (회색) | `surfaceContainerHighest` (회색) | ✅ 동일 |
| 아이콘 | `Sparkles` (h-3 w-3) | `AppIcons.sparkles` (12px) | ✅ 동일 |
| 패딩 | `px-2 py-1` (8×4px) | 미확인 | ⚠️ 확인 필요 |
| 폰트 크기 | `text-xs` (12px) | 미확인 | ⚠️ 확인 필요 |
| 삭제 버튼 | X 아이콘 (호버 시 표시) | **없음** | ❌ 누락 |
| **사용자 태그** | | | |
| 배경 색상 | `bg-primary` (강조색) | `primaryContainer` (강조색) | ✅ 동일 |
| 아이콘 | `Pencil` (h-3 w-3) | `#` 접두사 (텍스트) | ⚠️ 다름 |
| 삭제 버튼 | X 아이콘 (호버 시 표시) | **없음** | ❌ 누락 |
| **태그 추가 버튼** | `Plus` 아이콘 + "태그 추가" | **없음** | ❌ 누락 |

#### Fragment 카드 레이아웃

| 항목 | 웹 | 앱 |
|-----|-----|-----|
| 컨테이너 | `bg-card border rounded-lg p-4` | `ShadCard` (Shadcn) |
| 호버 효과 | `hover:shadow-md` | 없음 (모바일) |
| 텍스트 | 16px, leading-relaxed | 16px, lineHeight 1.6 |
| 이미지 크기 | 128×128 | 128×128 |
| 이미지 레이아웃 | `flex gap-2 flex-wrap` | `Wrap spacing: 8` |

**차이점**:
- 웹: 더보기 메뉴 (MoreVertical) 있음
- 앱: 더보기 메뉴 없음 → 편집/삭제 불가

#### 이벤트 시간 표시

| 항목 | 웹 | 앱 |
|-----|-----|-----|
| 클릭 동작 | Popover 열림 (DatePicker/TimePicker) | **없음** |
| 상대 시간 | "N분 전", "N시간 전" | "N분 전", "N시간 전" |
| 절대 시간 | "M월 d일" (시간 포함/미포함) | "M월 d일" |
| 아이콘 | AI: Sparkles, User: Calendar, Auto: Clock | 동일 |

**차이점**:
- 웹: 클릭하면 수정 가능
- 앱: 표시만 (수정 불가)

### ❌ 누락된 기능 (우선순위)

#### 🔴 Critical (즉시 수정 필요)

1. **편집 기능**
   - **웹**: DropdownMenu > 수정 → Textarea 표시 → 저장/취소
   - **앱**: 없음
   - **영향**: 오타 수정 불가, 사용자 불만 직결
   - **구현 위치**: `FragmentCard.svelte` L77-102
   - **필요 작업**:
     - 더보기 메뉴 (BottomSheet) 추가
     - 편집 모드 상태 관리
     - ShadTextarea 사용
     - 저장: `updateFragment(id, {content})` 호출

2. **삭제 기능**
   - **웹**: DropdownMenu > 삭제 → Dialog 확인 → 논리 삭제
   - **앱**: 없음
   - **영향**: 잘못 입력한 Fragment 제거 불가
   - **구현 위치**: `FragmentCard.svelte` L104-115
   - **필요 작업**:
     - 더보기 메뉴에 삭제 옵션 추가
     - ShadDialog 확인창
     - `deleteFragment(id)` 호출

#### 🟠 High (빠른 시일 내 수정)

3. **사용자 태그 추가**
   - **웹**: "태그 추가" 버튼 → 인라인 입력창 → Enter로 추가
   - **앱**: 없음
   - **영향**: 사용자가 직접 태그를 추가할 수 없음 (AI 태그만)
   - **구현 위치**: `FragmentCard.svelte` L321-332
   - **필요 작업**:
     - 태그 영역 아래 "태그 추가" 버튼
     - TextField 표시/숨김 상태 관리
     - Enter 키 감지 → `addUserTag(id, tag)` 호출

4. **사용자 태그 삭제**
   - **웹**: 태그 X 버튼 → 확인 UI → 삭제
   - **앱**: 없음
   - **영향**: 잘못 추가한 태그 제거 불가
   - **구현 위치**: `FragmentCard.svelte` L334-342
   - **필요 작업**:
     - 태그에 IconButton (X) 추가
     - 확인 UI (인라인 또는 Dialog)
     - `removeUserTag(id, tag)` 호출

5. **AI 태그 숨기기**
   - **웹**: AI 태그 X 버튼 → 확인 UI → 로컬에서 숨김
   - **앱**: 없음
   - **영향**: AI가 잘못 생성한 태그를 숨길 수 없음
   - **구현 위치**: `FragmentCard.svelte` L344-352
   - **필요 작업**:
     - AI 태그에 IconButton (X) 추가
     - 확인 UI
     - 로컬 DB에서 태그 제거 (서버는 유지)

6. **이벤트 시간 수정**
   - **웹**: 시간 클릭 → Popover → DatePicker/TimePicker → 저장
   - **앱**: 없음
   - **영향**: AI가 잘못 감지한 시간을 수정할 수 없음
   - **구현 위치**: `FragmentCard.svelte` L154-251
   - **필요 작업**:
     - 시간 GestureDetector → showDatePicker/showTimePicker
     - 시간 포함 여부 토글 (Checkbox)
     - `updateFragment(id, {eventTime, eventTimeSource})` 호출

#### 🟡 Medium (필수는 아니지만 권장)

7. **이미지 뷰어**
   - **웹**: 이미지 클릭 → Fullscreen 모달 → ESC/배경 클릭으로 닫기
   - **앱**: 없음
   - **영향**: 이미지 상세 확인 불편
   - **구현 위치**: `FragmentCard.svelte` L717-750
   - **필요 작업**:
     - CachedNetworkImage에 GestureDetector
     - Fullscreen Dialog
     - InteractiveViewer (확대/축소)

8. **Embedding 생성** (프리미엄 전용)
   - **웹**: DropdownMenu > 생성/재생성 → Edge Function 호출 → Realtime 업데이트
   - **앱**: 없음
   - **영향**: 프리미엄 사용자 기능 누락
   - **구현 위치**: `FragmentCard.svelte` L258-319
   - **필요 작업**:
     - 더보기 메뉴에 "Embedding 생성" 추가
     - Edge Function 호출 (`generate-embedding`)
     - 로딩 상태 표시
     - 30초 timeout

9. **Draft 연결 표시**
   - **웹**: Draft에 포함된 Fragment는 "제안: {title}" 표시 → 클릭 시 Draft 페이지 이동
   - **앱**: 없음
   - **영향**: Fragment-Draft 연결 확인 불가
   - **구현 위치**: `FragmentCard.svelte` L628-639
   - **필요 작업**:
     - Draft 조회 (fragmentId 포함 여부)
     - Draft 제목 표시 (primary/10 배경)
     - GestureDetector → Draft 페이지 이동

10. **동기화 상태 표시**
    - **웹**: `synced=0`일 때 Clock 아이콘 + "동기화 대기 중"
    - **앱**: 없음
    - **영향**: 동기화 실패 감지 어려움
    - **구현 위치**: `FragmentCard.svelte` L647-651
    - **필요 작업**:
      - `synced` 필드 확인
      - Clock 아이콘 + 텍스트 표시

11. **태그 클릭 필터**
    - **웹**: 태그 클릭 → Timeline에서 해당 태그로 필터링
    - **앱**: 없음
    - **영향**: 태그별 Fragment 빠른 검색 불가
    - **구현 위치**: `FragmentCard.svelte` L488-501
    - **필요 작업**:
      - 태그에 GestureDetector 추가
      - FilterBarProvider에 태그 추가
      - UI 자동 갱신

#### 🔵 Low (선택적)

12. **붙여넣기 이미지 추가**
    - **웹**: Clipboard 이미지 감지 → 자동 추가
    - **앱**: 없음 (모바일에서 덜 중요)
    - **구현 위치**: `FragmentInput.svelte` L86-103

13. **드래그 앤 드롭 이미지**
    - **웹**: 드래그 이벤트 처리 → 이미지 추가
    - **앱**: 없음 (모바일에서 불필요)
    - **구현 위치**: `FragmentInput.svelte` L106-124

---

## Draft 비교

### ✅ 다국어 적용 상태
- **웹**: 모든 텍스트 `.tr()` 사용 ✅
- **앱**: 모든 텍스트 `.tr()` 사용 ✅
- **결론**: 완벽하게 적용됨.

### 🎨 UI/디자인 차이

#### 탭 구조

| 항목 | 웹 | 앱 | 비고 |
|-----|-----|-----|-----|
| **컴포넌트** | Shadcn Button (variant 전환) | Material FilterChip | ❌ 다름 |
| **위치** | DraftList 상단 | DraftsPage 상단 |  |
| **필터** | All, Pending, Accepted, Rejected | 동일 | ✅ |
| **개수 표시** | 각 필터에 `(N)` | 각 필터에 `(N)` | ✅ |
| **디자인** | `variant="default"` vs `"outline"` | `selected` 상태 primaryContainer | ⚠️ |

**문제점**:
- **웹**: Shadcn UI Tabs 또는 Button 사용 (일관성 ✅)
- **앱**: Material FilterChip 사용 (**Shadcn UI 미사용**, 일관성 ❌)
- **수정 필요**: Shadcn UI 탭 컴포넌트가 있다면 사용, 없다면 ShadButton으로 교체

#### Draft 카드 디자인

| 항목 | 웹 | 앱 |
|-----|-----|-----|
| 컨테이너 | `bg-card border rounded-lg p-4` | Material Card |
| 제목 | `text-lg font-semibold` | `titleMedium fontWeight 600` |
| 이유 | `text-sm text-muted-foreground` | `bodySmall muted` |
| 상태 뱃지 | `px-2 py-1 rounded text-xs` | ShadBadge (pending/accepted/rejected) |

**차이점**:
- 웹: Card 스타일이 더 세밀함 (padding, gap, border)
- 앱: Material Card 기본 스타일 사용 → 웹과 통일감 부족

#### Fragment 목록 토글

| 항목 | 웹 | 앱 |
|-----|-----|-----|
| 버튼 | `variant="ghost" size="sm"` | ShadButton.ghost |
| 아이콘 | ChevronDown/ChevronRight | 동일 |
| 목록 스타일 | `pl-4 border-l-2 border-border` | `border-l, 회색 배경` |
| Fragment 표시 | `bg-muted rounded p-2` | 회색 배경, padding |

### ❌ 누락된 기능

#### 🔴 Critical

1. **Post 생성 페이지 자동 이동**
   - **웹**: Draft 수락 → `/posts/new?fragmentIds=...&draftId=...` 이동
   - **앱**: Draft 수락 → 상태만 변경 (페이지 이동 없음)
   - **영향**: 사용자가 수락 후 Post 생성 방법을 모름
   - **구현 위치**: `DraftCard.svelte` L67-80
   - **필요 작업**:
     - 수락 버튼 onPressed → `context.push('/posts/new?...')` 추가
     - fragmentIds, draftId 쿼리 파라미터 전달

#### 🟠 High

2. **피드백 신고 기능**
   - **웹**: DropdownMenu > 문제 신고 → FeedbackDialog → Supabase 저장
   - **앱**: 없음
   - **영향**: 잘못된 Draft에 대한 피드백 수집 불가 (AI 학습 불가)
   - **구현 위치**: `DraftCard.svelte` L360-369, `FeedbackDialog.svelte`
   - **필요 작업**:
     - Draft 카드에 더보기 메뉴 추가
     - FeedbackDialog (또는 BottomSheet) 구현
     - 템플릿 체크박스 + 자유 입력
     - `submitFeedback(targetType: 'draft', targetId, ...)` 호출
     - 중복 제출 방지 (`checkExistingFeedback`)

3. **무한 스크롤**
   - **웹**: IntersectionObserver + PAGE_SIZE 20 + sentinel
   - **앱**: 모든 Draft를 한 번에 로드
   - **영향**: Draft 개수가 많아지면 성능 저하
   - **구현 위치**: `DraftList.svelte` L84-112
   - **필요 작업**:
     - Isar `limit()` + `offset()` 쿼리
     - ScrollController + Listener
     - PAGE_SIZE 20
     - "모든 항목을 불러왔습니다" 메시지

#### 🟡 Medium

4. **Fragment 조회 최적화**
   - **웹**: `where('id').anyOf(fragmentIds)` (단일 쿼리)
   - **앱**: `for (var id in fragmentIds) getByRemoteID(id)` (N번 쿼리)
   - **영향**: Fragment 개수가 많으면 성능 저하
   - **구현 위치**: `DraftCard` initState
   - **필요 작업**:
     - Isar `where().anyOf()` 사용
     - 또는 `filter().remoteIDIn(fragmentIds)` 사용

---

## Post 비교

### ✅ 다국어 적용 상태
- **웹**: 모든 텍스트 `.tr()` 사용 ✅
- **앱**: 모든 텍스트 `.tr()` 사용 ✅

### ❌ 누락된 기능

#### 🔴 Critical (핵심 기능 누락)

1. **Post 생성 페이지 전체**
   - **웹**: `/posts/new` 라우트 + 템플릿 선택 + AI 스트리밍 생성
   - **앱**: **없음**
   - **영향**: **Post를 생성할 수 없음 (핵심 기능 누락)**
   - **구현 위치**: `/routes/posts/new/+page.svelte`
   - **필요 작업**:
     - **1단계: 템플릿 선택 화면**
       - 5가지 템플릿 (product_review, timeline, essay, travel, project)
       - AI 추천 템플릿 표시 (Lightbulb 아이콘)
       - 템플릿 설명 + 아이콘
       - 선택 상태 (border-primary, bg-primary/5)
     - **2단계: 무료 한도 체크**
       - `check_post_creation_limit` RPC 호출
       - 무료: 월 3개 제한
       - 초과 시 에러 메시지 + 프리미엄 업그레이드 버튼
     - **3단계: Post 생성 (스트리밍)**
       - Edge Function 호출 (`/functions/v1/generate-post`)
       - SSE (Server-Sent Events) 스트리밍
       - 이벤트 타입: `title`, `content`, `done`, `error`
       - 실시간 미리보기: 제목 + 내용 + 커서 애니메이션
       - 진행률 바
     - **4단계: 완료 후 이동**
       - `/posts/${postId}` 이동
   - **참고 코드**:
     - `/routes/posts/new/+page.svelte`
     - `/lib/services/post-generation.ts`
     - `/lib/templates/index.ts` (템플릿 정의)
     - `/lib/templates/auto-select.ts` (AI 추천)

#### 🟠 High

2. **Fragment 목록 토글**
   - **웹**: Post 상세에서 ChevronDown/ChevronRight → FragmentCard 리스트
   - **앱**: Fragment 개수만 표시
   - **영향**: 어떤 Fragment가 사용되었는지 확인 불가
   - **구현 위치**: `/routes/posts/[id]/+page.svelte` L240-265
   - **필요 작업**:
     - Post 상세에 Fragment 목록 섹션 추가
     - 토글 버튼 (ShadButton.ghost + ChevronDown/ChevronRight)
     - fragmentIds로 Isar 조회
     - FragmentCard 재사용

3. **내보내기 (Markdown 다운로드)**
   - **웹**: Download 아이콘 → Markdown 파일 다운로드
   - **앱**: 없음
   - **영향**: Post를 외부로 내보낼 수 없음
   - **구현 위치**: `/routes/posts/[id]/+page.svelte` L90-103
   - **필요 작업**:
     - Share 버튼 추가
     - `share_plus` 패키지 사용
     - Markdown 문자열 공유
     - 또는 파일로 저장 (`path_provider` + `File.writeAsString`)

4. **Post 재생성**
   - **웹**: RefreshCw 아이콘 → `/posts/new?previousVersionId=...` 이동
   - **앱**: 없음
   - **영향**: 다른 템플릿으로 재생성 불가
   - **구현 위치**: `/routes/posts/[id]/+page.svelte` L81-88
   - **필요 작업**:
     - Post 상세에 "다시 생성" 버튼 추가
     - fragmentIds + previousVersionId 전달
     - Post 생성 페이지로 이동

#### 🟡 Medium

5. **피드백 신고**
   - **웹**: Flag 아이콘 → FeedbackDialog
   - **앱**: 없음
   - **영향**: Post 품질 피드백 수집 불가
   - **구현 위치**: `/routes/posts/[id]/+page.svelte` L290-301
   - **필요 작업**:
     - FeedbackDialog (또는 BottomSheet) 구현
     - 4가지 템플릿: inaccurate, poor_writing, wrong_tone, too_short

6. **Preview/Source 모드 토글**
   - **웹**: 버튼 그룹 (미리보기/원본보기) → Markdown vs Text
   - **앱**: MarkdownBody만
   - **영향**: 원본 Markdown 확인 불가
   - **구현 위치**: `/routes/posts/[id]/+page.svelte` L209-237
   - **필요 작업**:
     - 상태 관리 (viewMode: preview | source)
     - 버튼 그룹 추가
     - source 모드: Text 위젯 (monospace)

7. **무한 스크롤**
   - **웹**: IntersectionObserver + PAGE_SIZE 20
   - **앱**: 단순 ListView
   - **영향**: Post 개수가 많아지면 성능 저하
   - **필요 작업**:
     - ScrollController + Listener
     - Isar `limit()` + `offset()`

---

## 수정 우선순위

### Phase 1: Critical (즉시 수정) - 1주

**Fragment**:
1. 편집 기능 (더보기 메뉴 + Textarea)
2. 삭제 기능 (더보기 메뉴 + Dialog)

**Draft**:
3. Post 생성 페이지 자동 이동 (수락 버튼)

**Post**:
4. **Post 생성 페이지 전체** (템플릿 선택 + AI 스트리밍)

### Phase 2: High (빠른 시일 내) - 1주

**Fragment**:
5. 사용자 태그 추가
6. 사용자 태그 삭제
7. AI 태그 숨기기
8. 이벤트 시간 수정

**Draft**:
9. 피드백 신고 기능
10. 탭 구조 Shadcn UI로 변경

**Post**:
11. Fragment 목록 토글
12. 내보내기
13. 재생성

### Phase 3: Medium (필수는 아니지만 권장) - 1주

**Fragment**:
14. 이미지 뷰어
15. Embedding 생성
16. Draft 연결 표시
17. 동기화 상태 표시
18. 태그 클릭 필터

**Draft**:
19. 무한 스크롤
20. Fragment 조회 최적화

**Post**:
21. 피드백 신고
22. Preview/Source 모드 토글
23. 무한 스크롤

### Phase 4: Low (선택적) - 선택

**Fragment**:
24. 붙여넣기 이미지 추가
25. 드래그 앤 드롭 이미지

---

## 예상 작업량

### Fragment (총 8일)
- 편집/삭제: 2일
- 태그 관리 (추가/삭제/숨기기): 2일
- 이벤트 시간 수정: 1일
- 이미지 뷰어: 0.5일
- Embedding 생성: 1일
- Draft 연결: 0.5일
- 동기화 상태: 0.5일
- 태그 클릭 필터: 0.5일

### Draft (총 3일)
- Post 생성 페이지 이동: 0.5일
- 피드백 신고: 1.5일
- Shadcn UI 탭: 0.5일
- 무한 스크롤: 0.5일

### Post (총 7일)
- **Post 생성 페이지**: 4일 (템플릿 선택 1일 + SSE 스트리밍 2일 + UI 1일)
- Fragment 목록: 0.5일
- 내보내기: 0.5일
- 재생성: 0.5일
- 피드백 신고: 1일
- Preview/Source: 0.5일

**총 예상 작업량**: 18일 (약 3.5주)

---

## 핵심 문제 요약

1. **Fragment 카드 세부 디자인 차이**: 태그 칩은 유사하지만, 편집/삭제/태그 관리 기능 누락으로 인터랙션 자체가 없음
2. **Fragment 카드 세부 기능 누락**: 편집, 삭제, 태그 관리, 이벤트 시간 수정, 이미지 뷰어, Embedding 생성 등 **10개 이상 기능 누락**
3. **Fragment 다국어**: ✅ 완벽 적용 (문제 없음)
4. **Draft 탭 구조**: Shadcn UI 미사용, Material FilterChip 사용 (일관성 부족)
5. **Draft 세부 디자인**: Card 스타일이 웹과 다름 (padding, gap, border)
6. **Draft 세부 기능**: 피드백 신고, 무한 스크롤, Post 생성 페이지 이동 누락
7. **Post 세부 기능**: **Post 생성 페이지 전체 누락** (핵심 기능), Fragment 목록, 내보내기, 재생성 등 누락

**즉시 수정 필요 항목**:
- Fragment 편집/삭제
- Draft → Post 생성 플로우
- **Post 생성 페이지 구현** (최우선)
