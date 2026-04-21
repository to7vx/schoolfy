import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform. '
      'This is a web-only application.',
    );
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
}
