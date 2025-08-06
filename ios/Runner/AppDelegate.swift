/// A description
import UIKit
import Flutter
import GoogleMaps // 🔥 BU SATIRI EKLE

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GMSServices.provideAPIKey("AIzaSyBb4rxfH9j2vuL9hm6Rr1dZ3jKqgx6dxX8") // 🔥 BU SATIRI EKLE

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
