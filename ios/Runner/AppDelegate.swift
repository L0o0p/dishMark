import Flutter
import UIKit
import AMapFoundationKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 高德地图key
    AMapServices.shared().apiKey = "8dc446dcf3651779abbd5df092b607a7"

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    let handledByFlutter = super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )

    if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
      // Claim Universal Links to avoid fallback back to Safari/WebView.
      return true
    }

    return handledByFlutter
  }
}
