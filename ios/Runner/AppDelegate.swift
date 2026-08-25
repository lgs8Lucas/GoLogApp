import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = googleMapsApiKey() {
      GMSServices.provideAPIKey(apiKey)
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Extrai GOOGLE_MAPS_API_KEY dos dart-defines expostos pelo Flutter via
  // Info.plist (mesmo mecanismo do lado Android, ver android/app/build.gradle.kts).
  private func googleMapsApiKey() -> String? {
    guard let dartDefines = Bundle.main.infoDictionary?["DartDefines"] as? String else {
      return nil
    }
    for encoded in dartDefines.split(separator: ",") {
      guard let data = Data(base64Encoded: String(encoded)),
            let decoded = String(data: data, encoding: .utf8) else { continue }
      let parts = decoded.split(separator: "=", maxSplits: 1)
      if parts.count == 2, parts[0] == "GOOGLE_MAPS_API_KEY" {
        return String(parts[1])
      }
    }
    return nil
  }
}
