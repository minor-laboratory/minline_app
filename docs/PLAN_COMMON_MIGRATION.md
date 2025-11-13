# minorlab_common 이동 계획

**작성일**: 2025-01-13
**대상**: 북랩 → minorlab_common

## 개요

북랩에 구현된 기능 중 다른 앱(미니라인, 밥플랜 등)에서도 재사용 가능한 항목을 minorlab_common으로 이동합니다.

## 이동 가능 항목

### 1. PasswordChangePage ✅ (높은 우선순위)

**파일**: `lib/features/profile/presentation/pages/password_change_page.dart`

**이유:**
- 앱 독립적인 로직 (AuthRepository만 의존)
- UI는 완전히 공통
- 다국어 키만 정리하면 바로 사용 가능

**의존성:**
- ✅ AuthRepository (이미 common에 있어야 함)
- ✅ Shadcn UI
- ✅ easy_localization

**이동 후 사용 방법:**
```dart
import 'package:minorlab_common/minorlab_common.dart';

// 라우터에 추가
GoRoute(
  path: '/profile/password',
  builder: (context, state) => const PasswordChangePage(),
),
```

### 2. AccountWithdrawalPage ⚠️ (조건부)

**파일**: `lib/features/settings/presentation/pages/account_withdrawal_page.dart`

**이유:**
- 기본 로직은 공통
- 구독 체크는 선택적 (builder pattern으로 분리 가능)

**수정 필요:**
```dart
// Before (북랩)
final subscriptionAsync = ref.watch(subscriptionStateProvider);
if (hasActiveSubscription) { ... }

// After (common - 선택적 파라미터)
class AccountWithdrawalPage extends ConsumerWidget {
  final bool showSubscriptionWarning;
  final Future<bool> Function()? checkSubscription;

  const AccountWithdrawalPage({
    this.showSubscriptionWarning = false,
    this.checkSubscription,
  });
}
```

**판단**: 당장은 보류, 필요하면 나중에 이동

### 3. 간단한 로그아웃 다이얼로그 ✅ (신규 작성)

**현재 LogoutConfirmationDialog 문제:**
- LocalChangeTracker 의존 (북랩 전용)
- Books/Records/Memos 하드코딩

**대안: common에 BaseLogoutDialog 추가**
```dart
// minorlab_common에 추가
class SimpleLogoutDialog extends StatelessWidget {
  final String? warningMessage;

  const SimpleLogoutDialog({this.warningMessage});
}

// 북랩에서는 기존 로직 유지
// 미니라인에서는 SimpleLogoutDialog 사용
```

### 4. UserProfileSection (부분 이동)

**파일**: `lib/features/profile/presentation/widgets/user_profile_section.dart`

**현재 문제:**
- 북랩 라우트 하드코딩 (`/home/profile/detail`)
- NetworkAwareProfileImage (북랩 전용?)

**대안:**
- 기본 프로필 카드 위젯을 common에 추가
- 라우트는 파라미터로 받기

```dart
// minorlab_common 추가
class UserProfileCard extends ConsumerWidget {
  final VoidCallback? onTap;
  final String? customLoginRoute;

  const UserProfileCard({
    this.onTap,
    this.customLoginRoute,
  });
}
```

**판단**: Phase 2에서 고려

## 즉시 이동할 항목 (Phase 1)

### PasswordChangePage

**작업 순서:**
1. minorlab_common에 디렉토리 생성
   ```
   minorlab_common/
   └── lib/src/features/profile/
       └── pages/
           └── password_change_page.dart
   ```

2. 북랩 코드 복사 후 정리
   - 북랩 특화 import 제거
   - 다국어 키 정리
   - AuthRepository 참조 방식 확인

3. minorlab_common export 추가
   ```dart
   // minorlab_common.dart
   export 'src/features/profile/pages/password_change_page.dart';
   ```

4. 북랩에서 import 변경
   ```dart
   // Before
   import '../../../profile/presentation/pages/password_change_page.dart';

   // After
   import 'package:minorlab_common/minorlab_common.dart';
   // PasswordChangePage는 common에서 가져옴
   ```

5. 미니라인에서 바로 사용
   ```dart
   import 'package:minorlab_common/minorlab_common.dart';

   GoRoute(
     path: '/profile/password',
     builder: (context, state) => const PasswordChangePage(),
   ),
   ```

## 보류 항목 (Phase 2 or 나중에)

1. **AccountWithdrawalPage** - 구독 로직 분리 필요
2. **UserProfileSection** - 라우팅 추상화 필요
3. **LogoutConfirmationDialog** - 각 앱마다 커스터마이즈 필요

## 다국어 키 정리

### PasswordChangePage 필요 키

```yaml
# auth.yaml (이미 common에 있을 것)
current_password: "현재 비밀번호"
new_password: "새 비밀번호"
confirm_password: "비밀번호 확인"
password_change_title: "비밀번호 변경"
password_set_title: "비밀번호 설정"
password_mismatch: "비밀번호가 일치하지 않습니다"
password_too_short: "비밀번호는 최소 6자 이상이어야 합니다"
password_change_success: "비밀번호가 변경되었습니다"
password_change_failed: "비밀번호 변경에 실패했습니다"
```

## 현재 작업 범위 (미니라인 인증 구현)

**이동 작업은 보류하고, 당장 미니라인 구현에 집중:**

1. ✅ **PasswordChangePage** - 북랩 코드 그대로 복사 (미니라인 내부)
2. ✅ **AccountWithdrawalPage** - 북랩 코드 그대로 복사 (구독 체크 제거)
3. ✅ **간단한 로그아웃 다이얼로그** - 미동기화 체크 없는 버전 작성

**나중에 정리:**
- 미니라인 동작 확인 후
- 웹 버전 작업 시 common 이동 고려

## 체크리스트

- [ ] PasswordChangePage 미니라인에 복사
- [ ] AccountWithdrawalPage 미니라인에 복사 (구독 체크 제거)
- [ ] 간단한 로그아웃 다이얼로그 작성
- [ ] 북랩 ProfileEditPage 삭제
- [ ] (나중에) common 이동 검토

---

**결론**: 당장은 common 이동 없이 북랩 코드를 미니라인에 복사해서 사용. common 이동은 Phase 2에서 고려.
