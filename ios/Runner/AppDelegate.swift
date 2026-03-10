import Flutter
import UIKit
import AMapFoundationKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let navigationChannelName = "dishmark/navigation"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 高德地图key
    AMapServices.shared().apiKey = "8dc446dcf3651779abbd5df092b607a7"

    GeneratedPluginRegistrant.register(with: self)
    setupNavigationChannel()
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

  private func setupNavigationChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    let channel = FlutterMethodChannel(
      name: navigationChannelName,
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "launchNavigation" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard
        let args = call.arguments as? [String: Any],
        let mapType = args["mapType"] as? String,
        let latitude = args["latitude"] as? Double,
        let longitude = args["longitude"] as? Double
      else {
        result(
          FlutterError(
            code: "INVALID_ARGS",
            message: "Missing map arguments",
            details: nil
          )
        )
        return
      }

      let placeName = (args["placeName"] as? String) ?? "目的地"
      self?.launchNavigation(
        mapType: mapType,
        latitude: latitude,
        longitude: longitude,
        placeName: placeName,
        result: result
      )
    }
  }

  private func launchNavigation(
    mapType: String,
    latitude: Double,
    longitude: Double,
    placeName: String,
    result: @escaping FlutterResult
  ) {
    let encodedName = encodeQueryComponent(placeName)
    let candidates = buildNavigationUrls(
      mapType: mapType,
      latitude: latitude,
      longitude: longitude,
      encodedName: encodedName
    )
    for urlString in candidates {
      guard let url = URL(string: urlString) else {
        continue
      }
      if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: [:]) { success in
          result(success)
        }
        return
      }
    }
    result(false)
  }

  private func buildNavigationUrls(
    mapType: String,
    latitude: Double,
    longitude: Double,
    encodedName: String
  ) -> [String] {
    switch mapType {
    case "amap":
      return [
        "iosamap://navi?sourceApplication=dishmark&lat=\(latitude)&lon=\(longitude)&dev=0&style=2",
        "iosamap://path?sourceApplication=dishmark&dlat=\(latitude)&dlon=\(longitude)&dname=\(encodedName)&dev=0&t=0"
      ]
    case "tencent":
      return [
        "qqmap://map/routeplan?type=drive&tocoord=\(latitude),\(longitude)&to=\(encodedName)&referer=dishmark",
        "qqmap://map/routeplan?type=drive&to=\(encodedName)&tocoord=\(latitude),\(longitude)&policy=1&referer=dishmark"
      ]
    case "baidu":
      return [
        "baidumap://map/direction?destination=latlng:\(latitude),\(longitude)|name:\(encodedName)&mode=driving&coord_type=gcj02&src=dishmark",
        "baidumap://map/navi?location=\(latitude),\(longitude)&query=\(encodedName)&src=dishmark"
      ]
    case "apple":
      return ["http://maps.apple.com/?daddr=\(latitude),\(longitude)&dirflg=d"]
    default:
      return []
    }
  }

  private func encodeQueryComponent(_ text: String) -> String {
    var allowed = CharacterSet.urlQueryAllowed
    allowed.remove(charactersIn: "&=?#+")
    return text.addingPercentEncoding(withAllowedCharacters: allowed) ?? "目的地"
  }

}
