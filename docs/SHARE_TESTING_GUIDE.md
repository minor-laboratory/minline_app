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

### ⚠️ iOS ShareExtension 필요

iOS에서 공유 기능을 완전히 사용하려면 **ShareExtension 타겟**을 Xcode에서 수동으로 추가해야 합니다.

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

## iOS 테스트 (ShareExtension 추가 후)

### 1. ShareExtension 타겟 추가 (Xcode 필요)

#### 단계 1: Xcode에서 프로젝트 열기

```bash
open ios/Runner.xcworkspace
```

#### 단계 2: Share Extension 타겟 추가

1. Xcode 프로젝트 네비게이터에서 Runner 프로젝트 선택
2. 하단 "+" 버튼 클릭 → "Target" 추가
3. "Share Extension" 템플릿 선택
4. Product Name: `ShareExtension`
5. Bundle ID: `com.minorlab.miniline.ShareExtension`
6. "Finish" 클릭

#### 단계 3: ShareViewController.swift 수정

생성된 `ShareViewController.swift` 파일을 다음과 같이 수정:

```swift
import UIKit
import share_handler_ios

class ShareViewController: ShareHandlerIosViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
```

#### 단계 4: Info.plist 수정

ShareExtension/Info.plist에서 `NSExtensionActivationRule` 수정:

```xml
<key>NSExtensionActivationRule</key>
<dict>
    <key>NSExtensionActivationSupportsText</key>
    <true/>
    <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
    <integer>1</integer>
    <key>NSExtensionActivationSupportsImageWithMaxCount</key>
    <integer>10</integer>
</dict>
```

#### 단계 5: App Group 설정

1. Runner 타겟 선택 → "Signing & Capabilities"
2. "+ Capability" → "App Groups" 추가
3. Group ID: `group.com.minorlab.miniline`
4. ShareExtension 타겟에도 동일한 App Group 추가

#### 단계 6: Podfile 수정

`ios/Podfile`에 다음 추가:

```ruby
target 'ShareExtension' do
  use_frameworks!
  pod 'share_handler_ios_models', :path => '.symlinks/plugins/share_handler_ios/ios/Models'
end
```

#### 단계 7: Pod 설치

```bash
cd ios
pod install
cd ..
```

### 2. iOS 빌드 및 실행

```bash
flutter run -d <ios-device>
```

### 3. iOS 테스트 방법

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
