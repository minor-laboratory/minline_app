# MiniLine 앱 배포 가이드

Fastlane을 사용한 iOS/Android 배포 가이드

## 📋 목차

1. [사전 준비사항](#사전-준비사항)
2. [iOS 배포 설정](#ios-배포-설정)
3. [Android 배포 설정](#android-배포-설정)
4. [배포 명령어](#배포-명령어)
5. [트러블슈팅](#트러블슈팅)

---

## 사전 준비사항

### 1. Fastlane 설치

```bash
# macOS (Homebrew 사용)
brew install fastlane

# 또는 RubyGems 사용
sudo gem install fastlane
```

---

## iOS 배포 설정

### 1. 환경 변수 설정 (북랩 키 재사용)

**북랩의 API 키를 그대로 사용합니다:**

```bash
# iOS .env 파일 생성
cat > ios/.env << 'EOF'
# App Store Connect API 설정 (북랩과 동일)
APP_STORE_CONNECT_API_KEY_ID="735FYAZFYQ"
APP_STORE_CONNECT_API_ISSUER_ID="9d62f38d-c457-429b-91d4-0f599099987a"
APP_STORE_CONNECT_API_KEY_PATH="/Users/heyoom/Documents/Github/minorlab_book/AuthKey_735FYAZFYQ.p8"

# App 정보 (MiniLine 앱 정보)
DEVELOPER_APP_IDENTIFIER="com.minorlab.miniline"
DEVELOPER_APP_ID="6755478595"
DEVELOPER_PORTAL_TEAM_ID="A968UAC4J8"  # 북랩과 동일
EOF
```

**설정 완료:**
- ✅ API 키: 북랩 키 재사용
- ✅ DEVELOPER_APP_ID: 6755478595 (설정 완료)

### 2. ExportOptions.plist 생성

```bash
# iOS ExportOptions.plist 생성
cat > ios/ExportOptions.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>teamID</key>
    <string>A968UAC4J8</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.minorlab.miniline</key>
        <string>com.minorlab.miniline AppStore</string>
        <key>com.minorlab.miniline.ShareExtension</key>
        <string>com.minorlab.miniline.ShareExtension AppStore</string>
    </dict>
</dict>
</plist>
EOF
```

---

## Android 배포 설정

### 1. 환경 변수 설정 (북랩 키 재사용)

**북랩의 Google Play Console 키를 그대로 사용합니다:**

```bash
# Android .env 파일 생성
cat > android/.env << 'EOF'
# Google Play Console API 설정 (북랩과 동일한 서비스 계정)
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH="/Users/heyoom/Documents/Github/minorlab_book/play-console-key.json"

# 패키지 정보
PACKAGE_NAME="com.minorlab.miniline"
EOF
```

**중요: 절대 경로 사용**
- ⚠️ 상대 경로는 fastlane 실행 위치에 따라 실패할 수 있으므로 **절대 경로** 사용 필수

**설정 완료:**
- ✅ API 키: 북랩 키 재사용
- ✅ 패키지명: com.minorlab.miniline
- ✅ Service Account 권한 추가 완료

### 2. 서명 키 설정 (북랩 키스토어 재사용)

북랩과 동일한 키스토어 및 alias를 사용합니다:

```bash
# Android key.properties 파일 생성
cat > android/key.properties << 'EOF'
storePassword=minorlab123
keyPassword=minorlab123
keyAlias=minorlab
storeFile=/Users/heyoom/Documents/Github/minorlab_configs/minorlab-release-keystore.jks
EOF
```

**중요: 절대 경로 사용**
- ⚠️ `storeFile`은 **절대 경로** 필수 (상대 경로는 fastlane 실행 시 실패)

**설정 완료:**
- ✅ 북랩과 동일한 키스토어 재사용
- ✅ 북랩과 동일한 alias (minorlab) 사용
- ✅ 별도 alias 생성 불필요

### 3. build.gradle.kts 서명 설정

**android/app/build.gradle.kts 수정:**

파일을 열어서 다음 내용을 추가:

```kotlin
// 파일 상단에 추가 (import 아래)
import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // 기존 내용...

    // signingConfigs 추가 (defaultConfig 위에)
    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }

    buildTypes {
        release {
            // 기존: signingConfig = signingConfigs.getByName("debug")
            // 변경:
            signingConfig = signingConfigs.getByName("release")

            // 나머지 기존 내용 유지...
        }
    }
}
```

---

## 배포 명령어

### iOS 배포

**1. TestFlight 베타 배포 (전체 빌드 + 업로드)**

```bash
cd ios
fastlane beta
```

**프로세스:**
1. Flutter 캐시 정리 (`flutter clean`)
2. 의존성 설치 (`flutter pub get`)
3. 코드 생성 (`build_runner`)
4. 아이콘/스플래시 생성
5. CocoaPods 설치
6. Flutter iOS 빌드
7. Xcode Archive 생성
8. IPA 파일 export
9. TestFlight 업로드

**2. IPA만 업로드 (빌드 제외)**

```bash
cd ios
fastlane upload_only
```

**3. 메타데이터/스크린샷 업로드**

```bash
# 메타데이터만
cd ios
fastlane metadata

# 스크린샷만
cd ios
fastlane screenshots
```

### Android 배포

**⚠️ 중요: 첫 배포 시 수동 업로드 필수**

Google Play API의 제한으로 **첫 번째 AAB는 Google Play Console에서 수동으로 업로드**해야 합니다.

**첫 수동 업로드 방법:**
1. AAB 빌드: `cd .. && flutter build appbundle --release`
2. Google Play Console → MiniLine → 릴리스 → 내부 테스트
3. 새 릴리스 만들기 → AAB 업로드
   - 파일 경로: `build/app/outputs/bundle/release/app-release.aab`
4. 릴리스 저장 및 시작

**이후부터는 fastlane으로 자동 배포 가능합니다.**

---

**1. 내부 테스트 트랙 배포 (자동)**

```bash
cd android
fastlane internal
```

**프로세스:**
1. Flutter AAB 빌드 (`flutter build appbundle --release`)
2. Google Play 내부 테스트 트랙에 업로드 (draft 상태)
3. Play Console에서 수동으로 릴리스 승인 필요

**참고:** 첫 AAB 수동 업로드 후에만 사용 가능

**2. Draft 릴리스 승격 (Completed로 변경)**

```bash
cd android
fastlane promote_internal
```

**3. 프로덕션 배포**

```bash
cd android
fastlane deploy
```

---

## 버전 관리

### 버전 업데이트 방법

**pubspec.yaml에서 버전 변경:**

```yaml
version: 1.0.1+2  # 1.0.1은 버전명, 2는 빌드 번호
```

**iOS 빌드 번호 업데이트:**

```ruby
# ios/fastlane/Fastfile의 beta lane에서
increment_build_number(
  xcodeproj: "Runner.xcodeproj",
  build_number: "2"  # 새 빌드 번호로 변경
)
```

**Android는 pubspec.yaml 버전이 자동 적용됩니다.**

---

## 트러블슈팅

### iOS 문제

**Q: "API 키를 찾을 수 없습니다" 에러**

```bash
# .env 파일 확인
cat ios/.env

# API 키 파일 확인
ls -la /Users/heyoom/Documents/Github/minorlab_book/AuthKey_735FYAZFYQ.p8
```

**Q: "Provisioning profile 오류"**

```bash
# Xcode에서 자동 서명 확인
open ios/Runner.xcworkspace

# Signing & Capabilities 탭에서 "Automatically manage signing" 체크
```

**Q: "IPA 파일을 찾을 수 없습니다"**

IPA 파일명이 `MiniLine.ipa`가 아닌 경우 Fastfile 수정:

```ruby
# ios/fastlane/Fastfile에서
ipa_path = File.join(project_root, 'build/ios/ipa/실제파일명.ipa')
```

### Android 문제

**Q: "Package not found: com.minorlab.miniline" 에러 (가장 흔한 문제)**

**원인:** Google Play API는 신규 앱 생성 및 첫 AAB 업로드를 지원하지 않습니다.

**해결 방법:**
1. Google Play Console에서 수동으로 첫 AAB 업로드 필수
2. 업로드 방법:
   - `flutter build appbundle --release` 실행
   - Google Play Console → MiniLine → 릴리스 → 내부 테스트
   - 새 릴리스 만들기 → `build/app/outputs/bundle/release/app-release.aab` 업로드
3. 첫 업로드 후부터 `fastlane internal` 사용 가능

**Q: "Service account 권한 오류"**

Service Account에 MiniLine 앱 접근 권한 추가 필요:
1. Google Play Console → 설정 → 사용자 및 권한
2. Service Account (`booklab-play-console@minor-lab.iam.gserviceaccount.com`) 선택
3. 앱 액세스 → 앱 추가 → MiniLine 선택
4. 관리자 또는 릴리스 관리자 권한 부여

**Q: "AAB 서명 오류"**

```bash
# key.properties 파일 확인
cat android/key.properties

# 키스토어 파일 존재 확인 (절대 경로 사용 필수)
ls -la /Users/heyoom/Documents/Github/minorlab_configs/minorlab-release-keystore.jks
```

**Q: "Package name mismatch"**

- `android/.env`의 `PACKAGE_NAME`과 `android/app/build.gradle.kts`의 `applicationId`가 일치하는지 확인

---

## 빠른 시작 체크리스트

### iOS (완료)

- [x] `ios/.env` 파일 생성 (북랩 API 키 재사용)
- [x] `DEVELOPER_APP_ID` 입력 (6755478595)
- [x] `ios/ExportOptions.plist` 생성 (provisioningProfiles 포함)
- [x] `cd ios && fastlane beta` 실행 → TestFlight 업로드 성공

### Android (완료)

- [x] `android/.env` 파일 생성 (북랩 API 키 재사용, 절대 경로)
- [x] `android/key.properties` 생성 (북랩 키스토어 재사용, 절대 경로)
- [x] `android/app/build.gradle.kts`에 서명 설정 추가
- [x] Service Account 권한 추가 (Google Play Console)
- [x] 첫 AAB 수동 업로드 완료 (내부 테스트)
- [x] 이후 `cd android && fastlane internal`로 자동 배포 가능

---

## 보안 체크리스트

- [ ] `.env` 파일이 `.gitignore`에 포함되어 있음 (✅ 이미 설정됨)
- [ ] `key.properties` 파일이 Git에 커밋되지 않음
- [ ] 키스토어 파일(`.jks`)이 Git에 커밋되지 않음
- [ ] 비밀번호가 코드에 하드코딩되지 않음

---

## 참고 자료

- [Fastlane 공식 문서](https://docs.fastlane.tools/)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [Google Play Console API](https://developers.google.com/android-publisher)
- 북랩 배포 설정 참조: `/Users/heyoom/Documents/Github/minorlab_book/ios/fastlane/`

---

**작성일**: 2025-11-20 (업데이트)
**작성자**: Claude Code
**프로젝트**: MiniLine App
**상태**: iOS/Android 배포 설정 완료
