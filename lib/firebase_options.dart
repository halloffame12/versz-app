import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'dart:io';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    } else if (Platform.isAndroid) {
      return android;
    } else if (Platform.isIOS) {
      return ios;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDklklsdlk_replace_with_real_key',
    appId: '1:123456789:android:abcdef1234567890abcdef',
    messagingSenderId: '123456789',
    projectId: 'versz-b4776',
    storageBucket: 'versz-b4776.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDklklsdlk_replace_with_real_key',
    appId: '1:123456789:ios:abcdef1234567890abcdef',
    messagingSenderId: '123456789',
    projectId: 'versz-b4776',
    storageBucket: 'versz-b4776.appspot.com',
    iosBundleId: 'app.versz.social',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDklklsdlk_replace_with_real_key',
    appId: '1:123456789:web:abcdef1234567890abcdef',
    messagingSenderId: '123456789',
    projectId: 'versz-b4776',
    authDomain: 'versz-b4776.firebaseapp.com',
    storageBucket: 'versz-b4776.appspot.com',
  );
}
