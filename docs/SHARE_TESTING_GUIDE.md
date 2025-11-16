# 공유 기능 테스트 가이드

## 개요

MiniLine 앱의 텍스트/이미지 공유 기능을 테스트하는 방법을 안내합니다.

## 현재 상태

### ✅ 완료된 설정

1. **Flutter 코드**
   - [lib/core/services/share_handler_service.dart](../lib/core/services/share_handler_service.dart) - 공유 수신 처리
   - [lib/main.dart](../lib/main.dart) - 서비스 초기화

2. **Android 설정**
   - [android/app/src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml) - Intent Filter 추가 완료
   - 텍스트 공유 (`text/plain`)
   - 이미지 공유 (단일/다중, `image/*`)

3. **iOS 설정 (부분 완료)**
   - [ios/Runner/Info.plist](../ios/Runner/Info.plist) - 기본 설정 완료
   - `CFBundleDocumentTypes` - 텍스트, URL, 이미지 타입 지원
   - `CFBundleURLTypes` - ShareMedia 딥링크 스킴
   - `NSUserActivityTypes` - ShareMedia
   - `NSPhotoLibraryUsageDescription` - 사진 라이브러리 권한

### ✅ iOS ShareExtension 완료

iOS ShareExtension이 이미 설정되어 있습니다. 추가 작업 불필요.

## Android 테스트 (즉시 가능)

### 1. 앱 빌드 및 실행

```bash
flutter run -d <android-device>
```

### 2. 텍스트 공유 테스트

#### 방법 1: Chrome 브라우저에서
1. Chrome 앱 열기
2. 아무 웹페이지 접속
3. 우측 상단 메뉴 (⋮) → "공유"
4. 공유 목록에서 "miniline_app" 선택
5. 앱이 열리고 Timeline 화면으로 이동하며 텍스트가 pre-fill되는지 확인

#### 방법 2: 메모 앱에서
1. 메모 앱에서 텍스트 작성
2. 텍스트 선택 → 공유 버튼
3. "miniline_app" 선택
4. 텍스트가 Timeline 입력창에 채워지는지 확인

### 3. 이미지 공유 테스트

#### 갤러리 앱에서
1. 갤러리 앱 열기
2. 이미지 하나 선택 (또는 여러 개 선택)
3. 공유 버튼 클릭
4. "miniline_app" 선택
5. 앱이 열리고 Timeline 화면으로 이동하며 이미지가 표시되는지 확인

### 4. 로그 확인

공유 수신 시 다음 로그가 출력됩니다:

```
[ShareHandler] Received shared media from stream
[ShareHandler] Processing media...
[ShareHandler] Content: <공유된 텍스트>
[ShareHandler] Attachments: <첨부파일 개수>
[ShareHandler] Navigating to timeline with text (또는 image)
```

## iOS 테스트 (즉시 가능)

### 이미 완료된 설정

다음 항목들이 이미 설정되어 있습니다:

1. ✅ ShareExtension 타겟 추가됨
2. ✅ ShareViewController.swift 구현됨 (share_handler_ios_models 상속)
3. ✅ Info.plist 설정됨 (텍스트, URL, 이미지 지원)
4. ✅ MainInterface.storyboard 추가됨
5. ✅ App Group 설정됨 (group.com.minorlab.miniline)
   - Runner.entitlements
   - ShareExtension.entitlements
6. ✅ Podfile에 ShareExtension 타겟 추가됨
7. ✅ lib/main.dart에서 iOS 공유 활성화됨 (Platform.isAndroid 제거)

**추가 작업 필요 없음** - 바로 테스트 가능합니다.

### 1. iOS 빌드 및 실행

```bash
flutter run -d <ios-device>
```

### 2. iOS 테스트 방법

#### 텍스트 공유
1. Safari 앱에서 웹페이지 접속
2. 공유 버튼 클릭
3. "Miniline App" 선택
4. 앱이 열리고 텍스트가 pre-fill되는지 확인

#### 이미지 공유
1. 사진 앱에서 이미지 선택
2. 공유 버튼 클릭
3. "Miniline App" 선택
4. 앱이 열리고 이미지가 표시되는지 확인

## 트러블슈팅

### Android

**문제**: 공유 목록에 앱이 표시되지 않음
- **해결**: 앱 재빌드 필요 (`flutter clean && flutter run`)
- AndroidManifest.xml 변경은 Hot Reload로 반영되지 않음

**문제**: 공유 시 앱이 열리지 않음
- **해결**: LogCat에서 에러 확인
  ```bash
  adb logcat | grep -i share
  ```

### iOS

**문제**: ShareExtension 타겟 빌드 실패
- **해결**: Pod 재설치
  ```bash
  cd ios
  pod deintegrate
  pod install
  cd ..
  ```

**문제**: App Group 설정 오류
- **해결**: Apple Developer 포털에서 App Group 등록 필요
- Xcode에서 "Automatically manage signing" 체크

## 참고

- **북랩 구현**: [../minorlab_book/lib/core/services/share_handler_service.dart](../../minorlab_book/lib/core/services/share_handler_service.dart)
- **share_handler 패키지**: https://pub.dev/packages/share_handler
- **share_plus 패키지**: https://pub.dev/packages/share_plus

---

**작성일**: 2025-11-16
**작성자**: Claude Code
