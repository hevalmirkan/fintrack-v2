// File generated/mocked for compilation.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyBeJAI7Z5CYVrpel4mAgYZTSlEBLFDDAEo',
    appId: '1:310430195356:web:124aa4bbe512258a1e9759',
    messagingSenderId: '310430195356',
    projectId: 'fintrack-v2',
    authDomain: 'fintrack-v2.firebaseapp.com',
    storageBucket: 'fintrack-v2.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCstjeExXIDZHVBro01tX_Qee0voTp9au8',
    appId: '1:310430195356:android:3f54a559e09c59de1e9759',
    messagingSenderId: '310430195356',
    projectId: 'fintrack-v2',
    storageBucket: 'fintrack-v2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAfNv6W5Vc_JqE3Rb5i8xblkRV-tJhK8ss',
    appId: '1:310430195356:ios:8d8a865bac8f99361e9759',
    messagingSenderId: '310430195356',
    projectId: 'fintrack-v2',
    storageBucket: 'fintrack-v2.firebasestorage.app',
    iosBundleId: 'com.hevalmirkan.fintrack',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'mock-api-key',
    appId: '1:1234567890:ios:mockid',
    messagingSenderId: '1234567890',
    projectId: 'fintrack-v2-mock',
    storageBucket: 'fintrack-v2-mock.appspot.com',
    iosBundleId: 'com.example.fintrackV2',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBeJAI7Z5CYVrpel4mAgYZTSlEBLFDDAEo',
    appId: '1:310430195356:web:e416fadcf835bfb91e9759',
    messagingSenderId: '310430195356',
    projectId: 'fintrack-v2',
    authDomain: 'fintrack-v2.firebaseapp.com',
    storageBucket: 'fintrack-v2.firebasestorage.app',
  );

}