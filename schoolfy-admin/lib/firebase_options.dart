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
    apiKey: 'AIzaSyBVZow_46m6Ek8yIaZy5xSsYrMdpHqKdEk',
    appId: '1:477357689953:web:cd6e01e525cc4222aeae20',
    messagingSenderId: '477357689953',
    projectId: 'schoolfy-706ff',
    authDomain: 'schoolfy-706ff.firebaseapp.com',
    databaseURL: 'https://schoolfy-706ff-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'schoolfy-706ff.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBR6FO9jqw_ic_YFAXz1b8K2ry2yhFVCBw',
    appId: '1:477357689953:android:cd6e01e525cc4222aeae20',
    messagingSenderId: '477357689953',
    projectId: 'schoolfy-706ff',
    databaseURL: 'https://schoolfy-706ff-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'schoolfy-706ff.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBR6FO9jqw_ic_YFAXz1b8K2ry2yhFVCBw',
    appId: '1:477357689953:ios:cd6e01e525cc4222aeae20',
    messagingSenderId: '477357689953',
    projectId: 'schoolfy-706ff',
    databaseURL: 'https://schoolfy-706ff-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'schoolfy-706ff.firebasestorage.app',
    iosBundleId: 'com.schoolfy.adminDashboard',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBR6FO9jqw_ic_YFAXz1b8K2ry2yhFVCBw',
    appId: '1:477357689953:macos:cd6e01e525cc4222aeae20',
    messagingSenderId: '477357689953',
    projectId: 'schoolfy-706ff',
    databaseURL: 'https://schoolfy-706ff-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'schoolfy-706ff.firebasestorage.app',
    iosBundleId: 'com.schoolfy.adminDashboard',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBVZow_46m6Ek8yIaZy5xSsYrMdpHqKdEk',
    appId: '1:477357689953:web:cd6e01e525cc4222aeae20',
    messagingSenderId: '477357689953',
    projectId: 'schoolfy-706ff',
    authDomain: 'schoolfy-706ff.firebaseapp.com',
    databaseURL: 'https://schoolfy-706ff-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'schoolfy-706ff.firebasestorage.app',
  );
}
