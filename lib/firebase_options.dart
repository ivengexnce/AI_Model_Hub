// File generated for BroML / ai_model_hub.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with BroML Firebase services.
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
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBgfZlPIRHuEy1E9YB66zGZNhG22I8Xcbg',
    appId: '1:640800735490:web:broml_web_app',
    messagingSenderId: '640800735490',
    projectId: 'broml-app',
    authDomain: 'broml-app.firebaseapp.com',
    storageBucket: 'broml-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBgfZlPIRHuEy1E9YB66zGZNhG22I8Xcbg',
    appId: '1:640800735490:android:e5bd1d38e364882b2b821b',
    messagingSenderId: '640800735490',
    projectId: 'broml-app',
    storageBucket: 'broml-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBgfZlPIRHuEy1E9YB66zGZNhG22I8Xcbg',
    appId: '1:640800735490:ios:broml_ios_app',
    messagingSenderId: '640800735490',
    projectId: 'broml-app',
    storageBucket: 'broml-app.firebasestorage.app',
  );
}

