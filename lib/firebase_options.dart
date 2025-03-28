// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
    apiKey: 'AIzaSyDNd0NHZ_3KoVdM_C1YcIdqN1zXstROvPQ',
    appId: '1:794795546739:web:1caadd670b6eea92957206',
    messagingSenderId: '794795546739',
    projectId: 'attendance-dci',
    authDomain: 'attendance-dci.firebaseapp.com',
    storageBucket: 'attendance-dci.firebasestorage.app',
    measurementId: 'G-KLH3092XHQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDNd0NHZ_3KoVdM_C1YcIdqN1zXstROvPQ',
    appId: '1:794795546739:android:248328d91c833d14957206',
    messagingSenderId: '794795546739',
    projectId: 'attendance-dci',
    storageBucket: 'attendance-dci.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBkW_01YnnzGwnOOsqzgRxmCtf4aZHWzS0',
    appId: '1:794795546739:ios:df5e2bc5bddfbb32957206',
    messagingSenderId: '794795546739',
    projectId: 'attendance-dci',
    storageBucket: 'attendance-dci.firebasestorage.app',
    iosBundleId: 'com.example.attendanceApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBkW_01YnnzGwnOOsqzgRxmCtf4aZHWzS0',
    appId: '1:794795546739:ios:df5e2bc5bddfbb32957206',
    messagingSenderId: '794795546739',
    projectId: 'attendance-dci',
    storageBucket: 'attendance-dci.firebasestorage.app',
    iosBundleId: 'com.example.attendanceApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDsxUiCpG4zr5kyUbuE147XIro7vX91HLQ',
    appId: '1:794795546739:web:edec2c227a7bdc0f957206',
    messagingSenderId: '794795546739',
    projectId: 'attendance-dci',
    authDomain: 'attendance-dci.firebaseapp.com',
    storageBucket: 'attendance-dci.firebasestorage.app',
    measurementId: 'G-1X6QH686NS',
  );
}
