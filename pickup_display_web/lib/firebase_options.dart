import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB73K2ABdwuqBLnVLqZ1zzZAmCDNx1ZnUw',
    appId: '1:477357689953:web:cd6e01e525cc4222aeae20',
    messagingSenderId: '477357689953',
    projectId: 'schoolfy-706ff',
    authDomain: 'schoolfy-706ff.firebaseapp.com',
    databaseURL: 'https://schoolfy-706ff-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'schoolfy-706ff.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC7rZJ_tZJ_8B4k8QpN7-QrJ9K3L5M6N7O8',
    appId: '1:123456789012:android:abc123def456',
    messagingSenderId: '123456789012',
    projectId: 'schoolfy-guardian',
    databaseURL: 'https://schoolfy-guardian-default-rtdb.firebaseio.com',
    storageBucket: 'schoolfy-guardian.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC7rZJ_tZJ_8B4k8QpN7-QrJ9K3L5M6N7O8',
    appId: '1:123456789012:ios:abc123def456',
    messagingSenderId: '123456789012',
    projectId: 'schoolfy-guardian',
    databaseURL: 'https://schoolfy-guardian-default-rtdb.firebaseio.com',
    storageBucket: 'schoolfy-guardian.appspot.com',
    iosClientId: '123456789012-abc123def456.apps.googleusercontent.com',
    iosBundleId: 'com.schoolfy.pickup_display_web',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC7rZJ_tZJ_8B4k8QpN7-QrJ9K3L5M6N7O8',
    appId: '1:123456789012:macos:abc123def456',
    messagingSenderId: '123456789012',
    projectId: 'schoolfy-guardian',
    databaseURL: 'https://schoolfy-guardian-default-rtdb.firebaseio.com',
    storageBucket: 'schoolfy-guardian.appspot.com',
    iosClientId: '123456789012-abc123def456.apps.googleusercontent.com',
    iosBundleId: 'com.schoolfy.pickup_display_web',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC7rZJ_tZJ_8B4k8QpN7-QrJ9K3L5M6N7O8',
    appId: '1:123456789012:web:abc123def456',
    messagingSenderId: '123456789012',
    projectId: 'schoolfy-guardian',
    authDomain: 'schoolfy-guardian.firebaseapp.com',
    databaseURL: 'https://schoolfy-guardian-default-rtdb.firebaseio.com',
    storageBucket: 'schoolfy-guardian.appspot.com',
    measurementId: 'G-ABCDEFGHIJ',
  );
}
