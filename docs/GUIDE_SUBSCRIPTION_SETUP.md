# 구독 기능 설정 가이드

MiniLine 앱의 RevenueCat 구독 기능 설정 방법입니다.

## 0. Apple App Store 가이드라인 필수 사항

### 필수 구현 요구사항

**Apple App Store Review Guidelines 3.1.2** 준수 사항:

1. **구매 복원 버튼** ✅
   - 구현 위치: `SubscriptionContent` 위젯
   - 모든 구독 화면에 "구매 복원" 버튼 제공

2. **구독 관리 링크** ✅
   - 구현 위치: `SettingsPage`
   - iOS에서만 "Apple 구독 관리" 링크 표시
   - 링크: `https://apps.apple.com/account/subscriptions`

3. **자동 갱신 정책 명시** ✅
   - 구현 위치: `SubscriptionContent` 위젯
   - "구독은 현재 기간이 끝나기 최소 24시간 전에 취소하지 않으면 자동으로 갱신됩니다" 문구 표시

4. **약관 및 개인정보처리방침 링크** ✅
   - 구현 위치: `SubscriptionContent` 위젯
   - 구독 화면 하단에 링크 제공

5. **명확한 가격 및 기간 표시** ✅
   - 구현 위치: `SubscriptionContent` 위젯
   - 각 패키지 카드에 가격과 기간 명시

### 주의사항

- 디지털 콘텐츠 판매는 반드시 In-App Purchase 사용
- 외부 결제 링크 제공 금지 (미국 제외)
- 구독은 최소 7일 이상 기간 제공 필요
- 모든 기기에서 구독 콘텐츠 접근 가능해야 함

**참고**: [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

## 1. RevenueCat 콘솔 설정

### 1.1 RevenueCat 프로젝트 생성

1. [RevenueCat Dashboard](https://app.revenuecat.com)에 접속
2. 새 프로젝트 생성 또는 기존 프로젝트 선택
3. iOS/Android 앱 추가

### 1.2 스토어 연동

**iOS (App Store Connect)**:
1. App Store Connect에서 In-App Purchase 상품 생성
2. RevenueCat → Apps → iOS → App Store Connect 연동
3. Shared Secret 입력

**Android (Google Play)**:
1. Google Play Console에서 구독 상품 생성
2. RevenueCat → Apps → Android → Google Play 연동
3. Service Account JSON 업로드

### 1.3 상품 설정

**Products 생성**:
- `miniline_premium_monthly` - 월간 구독
- `miniline_premium_yearly` - 연간 구독

**Offerings 설정**:
- Default Offering 생성
- Monthly/Annual 패키지 추가

**Entitlements 설정**:
- `Pro` Entitlement 생성 (중요: 정확히 "Pro"로 설정)
- 위 상품들을 Entitlement에 연결

## 2. 환경 변수 설정

### 2.1 API 키 확인

RevenueCat Dashboard → Project Settings → API Keys에서:
- iOS: Public App-Specific API Key
- Android: Public App-Specific API Key

### 2.2 .env.dev 파일 수정

```bash
# 기존 환경 변수
SUPABASE_URL=...
SUPABASE_ANON_KEY=...

# RevenueCat API 키 추가
REVENUECAT_API_KEY_IOS=appl_xxxxxxxxxxxxxxxx
REVENUECAT_API_KEY_ANDROID=goog_xxxxxxxxxxxxxxxx
```

### 2.3 코드 생성

```bash
cd miniline_app
dart run build_runner build --delete-conflicting-outputs
```

## 3. iOS 네이티브 설정

### 3.1 Capabilities 추가

Xcode에서:
1. Target → Signing & Capabilities
2. `+ Capability` → "In-App Purchase" 추가

### 3.2 StoreKit Configuration (테스트용)

1. File → New → File → StoreKit Configuration File
2. 상품 추가:
   - Type: Auto-Renewable Subscription
   - Product ID: `miniline_premium_monthly`, `miniline_premium_yearly`
   - Subscription Group: `premium`

3. Scheme 설정:
   - Edit Scheme → Run → Options
   - StoreKit Configuration → 생성한 파일 선택

## 4. Android 네이티브 설정

### 4.1 build.gradle 확인

`android/app/build.gradle`:
```gradle
dependencies {
    // RevenueCat SDK는 Flutter 플러그인이 자동 추가
}
```

### 4.2 BillingClient 권한

`android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="com.android.vending.BILLING" />
```
(일반적으로 자동 추가됨)

## 5. 테스트

### 5.1 iOS 테스트

**Sandbox 테스트**:
1. 테스트 계정 생성 (App Store Connect → Users and Access → Sandbox)
2. 기기에서 기존 Apple ID 로그아웃
3. 앱에서 구매 시 Sandbox 계정으로 로그인

**StoreKit Testing (시뮬레이터)**:
- StoreKit Configuration File 사용 시 시뮬레이터에서 구매 테스트 가능

### 5.2 Android 테스트

**License Testers 설정**:
1. Google Play Console → Settings → License Testing
2. 테스트 계정 이메일 추가

**내부 테스트 트랙**:
1. Internal Testing 트랙에 앱 업로드
2. 테스터 추가 후 설치 링크 배포

## 6. 파일 구조

```
lib/
├── core/services/
│   ├── subscription_service.dart           # RevenueCat 래퍼
│   └── subscription_service_provider.dart  # Riverpod Provider
│
├── features/subscription/
│   ├── providers/
│   │   └── subscription_provider.dart      # 무료 한도 Provider (Supabase)
│   └── presentation/
│       ├── pages/
│       │   └── subscription_page.dart      # 전체 화면 (설정에서)
│       └── widgets/
│           ├── subscription_content.dart   # 핵심 UI (재사용)
│           └── subscription_sheet.dart     # BottomSheet (한도 초과)
```

**중요 개념**:
- **subscription_service**: RevenueCat API 직접 호출 (실시간 구독 상태)
- **subscription_provider**: Supabase DB 조회 (무료 한도 추적, 캐시됨)

## 7. 무료 한도 및 크로스앱 구독

### 7.1 무료 한도

**무료 사용자**: 월 5개 글 생성
- `user_subscriptions.free_posts_count` 추적
- 매월 1일 자동 리셋
- 한도 초과 시 Paywall 표시

**프리미엄 사용자**: 무제한
- RevenueCat Entitlement `Pro` 보유
- 한도 체크 건너뜀

### 7.2 크로스앱 구독 (중요)

**MinorLab 패밀리 앱은 하나의 구독을 공유합니다.**

- **북랩 앱**에서 구독 → 미니라인에서도 프리미엄
- **미니라인 앱**에서 구독 → 북랩에서도 프리미엄
- 모든 앱이 동일한 Supabase 백엔드 사용
- RevenueCat 웹훅이 `user_subscriptions.is_premium` 자동 동기화

**참고**: [GUIDE_SUBSCRIPTION_REVENUECAT.md](../../docs/common/GUIDE_SUBSCRIPTION_REVENUECAT.md)

## 8. 사용 방법

### 8.1 프리미엄 상태 확인

```dart
final isPremium = ref.watch(isPremiumProvider);

isPremium.when(
  data: (premium) {
    if (premium) {
      // 프리미엄 기능
    } else {
      // 무료 기능
    }
  },
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('Error'),
);
```

### 8.2 Paywall 표시

```dart
// BottomSheet로 표시 (무료 한도 초과 시)
final subscribed = await SubscriptionSheet.show(context);
if (subscribed == true) {
  // 구독 완료
}

// 전체 화면으로 이동 (설정에서)
context.push('/settings/subscription');
```

## 9. 체크리스트

### RevenueCat 설정
- [ ] RevenueCat 프로젝트 생성
- [ ] iOS App Store Connect 연동
- [ ] Android Google Play 연동
- [ ] Products 생성 (monthly, yearly)
- [ ] Offerings 설정 (default)
- [ ] Entitlements 설정 (Pro)

### 환경 변수
- [ ] `.env.dev`에 `REVENUECAT_API_KEY_IOS` 추가
- [ ] `.env.dev`에 `REVENUECAT_API_KEY_ANDROID` 추가
- [ ] `dart run build_runner build` 실행

### iOS
- [ ] In-App Purchase Capability 추가
- [ ] (선택) StoreKit Configuration File 생성
- [ ] Sandbox 테스터 계정 생성

### Android
- [ ] License Testers 설정
- [ ] 내부 테스트 트랙 설정

### 테스트
- [ ] iOS Sandbox 구매 테스트
- [ ] Android 테스트 구매
- [ ] 구매 복원 테스트
- [ ] 무료 한도 초과 시 Paywall 동작 확인

## 10. 트러블슈팅

### "No offerings available"
- RevenueCat에서 Offerings이 설정되었는지 확인
- 상품이 스토어에서 "Ready to Submit" 상태인지 확인
- API 키가 올바른지 확인

### iOS 구매 실패
- Sandbox 계정으로 로그인했는지 확인
- In-App Purchase Capability가 추가되었는지 확인
- 앱 Bundle ID가 일치하는지 확인

### Android 구매 실패
- Google Play 서비스가 최신인지 확인
- License Testers에 계정이 추가되었는지 확인
- 앱이 Play Console에 업로드되었는지 확인

---

**작성일**: 2024-11-21
**최종 수정**: 2024-11-21
