import Flutter
import UIKit
import Firebase   // ✅ 반드시 필요
import GoogleSignIn   // ✅ 추가


@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()   // ✅ 추가
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
      override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
      ) -> Bool {
        if GIDSignIn.sharedInstance.handle(url) { return true }
        return super.application(app, open: url, options: options)
      }
}
