# 인트로 페이지 구현

> 작성: 2025-11-21

**언제 읽어야 하는가:**
- Flutter 구현 시작 전
- 미드저니 프롬프트 확정 시
- 라우팅 수정 시

## Flutter 구현

### 파일 구조

```
lib/features/intro/
├── presentation/
│   ├── pages/
│   │   └── intro_page.dart
│   └── widgets/
│       ├── intro_slide.dart
│       └── page_indicator.dart
└── providers/
    └── intro_provider.dart
```

### 라우팅

```dart
// app_router.dart에 추가
GoRoute(
  path: '/intro',
  name: 'intro',
  builder: (context, state) => const IntroPage(),
),
```

### 첫 실행 감지

```dart
// intro_provider.dart
const _introCompletedKey = 'intro_completed';

@riverpod
class IntroState extends _$IntroState {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_introCompletedKey) ?? false;
  }

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introCompletedKey, true);
    state = const AsyncValue.data(true);
  }
}
```

### 앱 시작 분기

```dart
// main.dart 또는 app_router.dart
final introCompleted = await ref.read(introStateProvider.future);
if (!introCompleted) {
  context.go('/intro');
} else {
  context.go('/');
}
```

### IntroPage 구조

```dart
class IntroPage extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 건너뛰기 버튼 (마지막 페이지 제외)
            if (currentPage < 2)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipIntro,
                  child: Text('intro.skip'.tr()),
                ),
              ),

            // PageView (일러스트 + 텍스트)
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => currentPage = index),
                children: [
                  IntroSlide(
                    image: 'assets/images/intro_1.png',
                    title: 'intro.page1.title'.tr(),
                    description: 'intro.page1.description'.tr(),
                  ),
                  // ... page 2, 3
                ],
              ),
            ),

            // 페이지 인디케이터
            PageIndicator(currentPage: currentPage, totalPages: 3),

            // 시작하기 버튼 (마지막 페이지만)
            if (currentPage == 2)
              ShadButton(
                onPressed: _completeIntro,
                child: Text('intro.start'.tr()),
              ),
          ],
        ),
      ),
    );
  }
}
```

## 다국어 키

```json
// ko.json
{
  "intro": {
    "skip": "건너뛰기",
    "start": "MiniLine 시작하기",
    "page1": {
      "title": "생각을 기록하고 싶은데...",
      "description": "일기는 부담스럽고\n메모는 어디 갔는지 모르겠고"
    },
    "page2": {
      "title": "그냥 짧게 적기만 하면 돼요",
      "description": "\"점심에 파스타 먹음\"\n\"친구가 추천한 식당이었는데\"\n언제 어디서든"
    },
    "page3": {
      "title": "AI가 하나의 이야기로 만들어줘요",
      "description": "시간을 넘어 자동으로 연결\n완성된 글로 조합"
    }
  }
}
```

## 미드저니 프롬프트 (초안)

> 캐릭터 선정 후 수정 예정

### 공통 스타일

- 미니멀리스트 일러스트레이션
- 소프트 파스텔, 부드러운 그라데이션
- 비율: --ar 9:16
- 버전: --v 7

### 화면 1 프롬프트

```
A minimalist illustration of scattered notebooks, sticky notes, and diary
pages floating in a soft gray gradient space, items are disorganized and
disconnected, muted color palette with gentle blues and grays, papers
slightly tilted at different angles creating sense of chaos, soft shadows,
dreamy atmosphere, top-down perspective, negative space, calm but messy
feeling, --ar 9:16 --style raw --v 7
```

### 화면 2 프롬프트

```
A minimalist illustration of smartphone screen with short text fragments
appearing one by one, floating text bubbles saying simple phrases in Korean
style, soft pastel pink and lavender gradient background, clean modern
interface, gentle glow around phone, sparkles or small stars floating nearby,
hopeful and light atmosphere, centered composition, plenty of breathing room,
--ar 9:16 --style raw --v 7
```

### 화면 3 프롬프트

```
A minimalist illustration of scattered fragments connecting into constellation
pattern, small glowing dots linked by golden lines forming a complete story
document at center, warm gradient background transitioning from soft pink to
golden yellow, magical particles and light rays, fragments transforming into
unified whole, sense of completion and harmony, inspiring atmosphere, gentle
bloom effect, --ar 9:16 --style raw --v 7
```

## 검증 체크리스트

- [ ] 모든 텍스트 `.tr()` 사용
- [ ] 이미지 assets 등록
- [ ] SharedPreferences 키 상수화
- [ ] `flutter analyze` 통과
- [ ] 실기기 테스트 (iOS, Android)
