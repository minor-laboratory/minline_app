import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let CHANNEL = "com.minorlab.miniline/share"
  private var isFromShare = false
  private var sharedData: [String: Any]?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // flutter_local_notifications: 포그라운드 알림 지원
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)

    // Method Channel 설정
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: CHANNEL,
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate is nil", details: nil))
        return
      }

      switch call.method {
      case "isShareActivity":
        print("✅ iOS isShareActivity called: \(self.isFromShare)")
        result(self.isFromShare)
      case "getSharedData":
        print("✅ iOS getSharedData called: \(self.sharedData != nil)")
        result(self.sharedData)
      case "closeShareActivity":
        print("✅ iOS closeShareActivity called")
        // iOS에서는 앱 종료
        exit(0)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    print("🔗 iOS received URL: \(url.absoluteString)")

    // Share Extension에서 URL Scheme으로 앱 열기
    if url.scheme == "miniline" && url.host == "share" {
      print("✅ iOS Share URL detected!")
      isFromShare = true
      loadSharedDataFromAppGroup()

      // Window를 투명하게 설정
      if let window = window {
        window.backgroundColor = UIColor.clear
        window.isOpaque = false
      }

      return true
    }

    return super.application(app, open: url, options: options)
  }

  /// App Group에서 공유 데이터 로드
  private func loadSharedDataFromAppGroup() {
    print("📦 iOS Loading shared data from App Group...")

    guard let appGroupId = Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String else {
      print("❌ iOS AppGroupId not found in Info.plist")
      return
    }

    print("📦 iOS AppGroupId: \(appGroupId)")

    guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
      print("❌ iOS UserDefaults creation failed for: \(appGroupId)")
      return
    }

    guard let data = userDefaults.dictionary(forKey: "ShareMedia") else {
      print("❌ iOS ShareMedia not found in App Group")
      return
    }

    print("✅ iOS Shared data loaded: \(data)")
    sharedData = data

    // 데이터 사용 후 삭제
    userDefaults.removeObject(forKey: "ShareMedia")
  }
}
