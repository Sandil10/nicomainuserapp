import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required for google_maps_flutter on iOS. Without this the app crashes
    // the moment a GoogleMap widget is rendered (e.g. delivery details,
    // order tracking). Android reads the key from AndroidManifest instead.
    GMSServices.provideAPIKey("AIzaSyBedirf6s8EnSButbonv6EWzAq7tqjmYns")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
