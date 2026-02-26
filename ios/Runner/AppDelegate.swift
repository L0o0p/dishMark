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
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    let handled = super.application(app, open: url, options: options)
    print("AppDelegate openURL: \(url.absoluteString), handled=\(handled)")
    return handled
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    let handled = super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
    let urlString = userActivity.webpageURL?.absoluteString ?? "(nil)"
    print("AppDelegate continueUserActivity: \(userActivity.activityType), url=\(urlString), handled=\(handled)")
    return handled
  }
}
