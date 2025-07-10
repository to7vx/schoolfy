import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyCAG_cWk1is1AtdgIltXEiyEcACrDQ_3K8',
    appId: '1:477357689953:web:67a068b24743c359aeae20',
    messagingSenderId: '477357689953',
    projectId: 'schoolfy-706ff',
    authDomain: 'schoolfy-706ff.firebaseapp.com',
    databaseURL: 'https://schoolfy-706ff-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'schoolfy-706ff.firebasestorage.app',
    measurementId: 'G-N90V441LVJ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBBmzUH1u7SWL6jXVNdqYw8rHNxHcvJIgI',
    appId: '1:1046994509305:android:7a3e7a45c6f47e4dd8e70e',
    messagingSenderId: '1046994509305',
    projectId: 'schoolfy-706ff',
    databaseURL: 'https://schoolfy-706ff-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'schoolfy-706ff.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBJ-mP5Y7x2j9hTVKv4QG8Y7mY-6rGdBE4',
    appId: '1:1046994509305:ios:3c9e7d4e5f6g8h9id8e70e',
    messagingSenderId: '1046994509305',
    projectId: 'schoolfy-706ff',
    databaseURL: 'https://schoolfy-706ff-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'schoolfy-706ff.appspot.com',
    iosBundleId: 'com.schoolfy.adminDashboard',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBJ-mP5Y7x2j9hTVKv4QG8Y7mY-6rGdBE4',
    appId: '1:1046994509305:macos:4d9f8g0h1i2j3k4ld8e70e',
    messagingSenderId: '1046994509305',
    projectId: 'schoolfy-706ff',
    databaseURL: 'https://schoolfy-706ff-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'schoolfy-706ff.appspot.com',
    iosBundleId: 'com.schoolfy.adminDashboard',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCAG_cWk1is1AtdgIltXEiyEcACrDQ_3K8',
    appId: '1:477357689953:web:67a068b24743c359aeae20',
    messagingSenderId: '477357689953',
    projectId: 'schoolfy-706ff',
    authDomain: 'schoolfy-706ff.firebaseapp.com',
    databaseURL: 'https://schoolfy-706ff-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'schoolfy-706ff.firebasestorage.app',
    measurementId: 'G-N90V441LVJ',
  );
}
