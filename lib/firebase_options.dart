import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration per platform.
///
/// Use `DefaultFirebaseOptions.currentPlatform` so the right config is picked
/// automatically — hardcoding one platform (e.g. `.android`) crashes the app
/// on the other platform because the API key / app id don't match.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyDacvgiBE4E31TKnTD_k_DoPToT0uNId14",
    appId: "1:965088107395:android:ec53f02e0e6896f139f4b6",
    messagingSenderId: "965088107395",
    projectId: "aquaflow-q4fcn",
    storageBucket: "aquaflow-q4fcn.firebasestorage.app",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyCx69hhlfGZm8YoeAVCXtaUTyymmo72TWw",
    appId: "1:965088107395:ios:c331b9b3b9917fc039f4b6",
    messagingSenderId: "965088107395",
    projectId: "aquaflow-q4fcn",
    storageBucket: "aquaflow-q4fcn.firebasestorage.app",
    iosBundleId: "com.nicomart.app",
  );
}
